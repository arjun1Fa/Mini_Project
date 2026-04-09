"""
POST /api/analyze
Full ML pipeline: quality → YOLO-seg → Depth → Volume → Nutrition.
"""
import base64
import json
import time
import logging
import os

import cv2
import numpy as np
from flask import Blueprint, request, jsonify

from ..utils.image_quality import check_image_quality
from ..utils.auth import require_auth
from ..utils.nutrition_calculator import scale_nutrition, sum_nutrition, FALLBACK_NUTRITION
from ..ml.yolo_handler import run_segmentation
from ..ml.depth_handler import estimate_heights
from ..ml.volume_calculator import estimate_weight
from ..ml.shape_density_table import PLATE_DIAMETER_CM
from ..ml.vision_api_handler import analyze_with_gemini
from ..db.supabase_client import get_nutrition

# ── Feature flag: set USE_YOLO=True in .env to re-enable the local YOLO pipeline
USE_YOLO = os.getenv("USE_YOLO", "False").lower() in ("true", "1", "yes")

logger = logging.getLogger(__name__)

analyze_bp = Blueprint("analyze", __name__)

BLUR_THRESHOLD = float(os.getenv("BLUR_THRESHOLD", 100))
BRIGHTNESS_THRESHOLD = float(os.getenv("BRIGHTNESS_THRESHOLD", 50))


# ── Helper: mask → base64 PNG ─────────────────────────────────────────────────

def _mask_to_b64(mask: np.ndarray) -> str:
    """Encode a binary mask as a base64 PNG."""
    img = (mask * 255).astype(np.uint8)
    _, buf = cv2.imencode(".png", img)
    return base64.b64encode(buf).decode("utf-8")


# ── Helper: nutrition lookup (Supabase → local fallback) ─────────────────────

def _fetch_nutrition(food_class: str) -> dict:
    row = get_nutrition(food_class)
    if row:
        return row
    key = food_class.lower().replace(" ", "_").replace("-", "_")
    return FALLBACK_NUTRITION.get(key, FALLBACK_NUTRITION["unknown"])


# ── Plate pixel diameter → pixels per cm ─────────────────────────────────────

def _derive_pixel_per_cm(plate: dict, plate_type: str) -> float:
    """
    Use the largest plate bounding-box dimension as pixel diameter,
    then divide by the known real-world diameter.
    """
    bbox = plate.get("bbox", [0, 0, 100, 100])
    pixel_diameter = max(bbox[2], bbox[3])  # w or h
    real_cm = PLATE_DIAMETER_CM.get(plate_type, 25.0)
    return pixel_diameter / real_cm if pixel_diameter > 0 else 20.0


# ── Main endpoint ─────────────────────────────────────────────────────────────

@analyze_bp.route("/analyze", methods=["POST"])
@require_auth
def analyze():
    t0 = time.time()

    # ── 1. Parse inputs ───────────────────────────────────────────────────────
    if "image" not in request.files:
        return jsonify({"error": "missing_image", "message": "No image file provided"}), 400

    image_file = request.files["image"]
    plate_type = request.form.get("plate_type", "standard").lower()
    food_predictions_raw = request.form.get("food_predictions", "[]")

    try:
        food_predictions = json.loads(food_predictions_raw)
    except json.JSONDecodeError:
        food_predictions = []

    # ── 2. Decode image ───────────────────────────────────────────────────────
    file_bytes = np.frombuffer(image_file.read(), dtype=np.uint8)
    image_bgr = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
    if image_bgr is None:
        return jsonify({"error": "decode_error", "message": "Cannot decode image"}), 400

    image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)

    # ── 3. Quality gate ───────────────────────────────────────────────────────
    ok, err_code = check_image_quality(image_bgr, BLUR_THRESHOLD, BRIGHTNESS_THRESHOLD)
    if not ok:
        messages = {
            "image_too_blurry": "Please retake the photo — the image is too blurry.",
            "image_too_dark": "Please take the photo in better lighting.",
        }
        return jsonify({"error": err_code, "message": messages.get(err_code, "Image quality issue")}), 422

    # ── 4 & 5 & 6. Food identification + weight estimation ───────────────────
    items = []

    if USE_YOLO:
        # ── Legacy YOLO + Depth + Volume pipeline (disabled, preserved for future use)
        seg_result = run_segmentation(image_rgb, food_predictions)
        plate = seg_result["plate"]
        foods = seg_result["foods"]
        pixel_per_cm = _derive_pixel_per_cm(plate, plate_type)
        food_masks = [f["mask"] for f in foods]
        heights_cm = estimate_heights(image_rgb, food_masks, pixel_per_cm)

        for food, height_cm in zip(foods, heights_cm):
            cls = food["class_name"]
            weight_g = estimate_weight(cls, food["area_px"], pixel_per_cm, height_cm)
            nutrition_raw = _fetch_nutrition(cls)
            nutrition = scale_nutrition(nutrition_raw, weight_g)
            items.append({
                "food_name": cls.replace("_", " ").title(),
                "food_key": cls,
                "confidence": round(food["confidence"], 3),
                "weight_g": round(weight_g, 1),
                "bounding_box": {"x": food["bbox"][0], "y": food["bbox"][1], "w": food["bbox"][2], "h": food["bbox"][3]},
                "segmentation_mask_b64": _mask_to_b64(food["mask"]),
                "nutrition": nutrition,
            })
    else:
        # ── NEW: Gemini Vision API pipeline ───────────────────────────────────
        gemini_foods = analyze_with_gemini(image_rgb)
        for food in gemini_foods:
            cls = food["food_name"]
            weight_g = food["weight_g"]
            nutrition_raw = _fetch_nutrition(cls)
            nutrition = scale_nutrition(nutrition_raw, weight_g)
            items.append({
                "food_name": cls.replace("_", " ").title(),
                "food_key": cls,
                "confidence": round(food["confidence"], 3),
                "weight_g": round(weight_g, 1),
                "bounding_box": {"x": 0, "y": 0, "w": 0, "h": 0},
                "segmentation_mask_b64": "",
                "nutrition": nutrition,
            })

    total = sum_nutrition(items)
    processing_ms = int((time.time() - t0) * 1000)

    # pixel_per_cm is only meaningful in the YOLO path; use 0 for Gemini path
    ppcm = pixel_per_cm if USE_YOLO else 0.0

    return (
        jsonify(
            {
                "items": items,
                "total": total,
                "plate_pixel_per_cm": round(ppcm, 4),
                "processing_time_ms": processing_ms,
            }
        ),
        200,
    )
