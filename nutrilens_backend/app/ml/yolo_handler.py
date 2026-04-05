"""
YOLOv8-seg inference handler.
Falls back to a mock when the model file is absent (dev mode).
"""
import os
import logging
import numpy as np

logger = logging.getLogger(__name__)

_model = None
MODEL_PATH = os.path.join(os.getenv("MODEL_DIR", "models"), "yolov8_indian_food_seg.pt")


def _load_model():
    global _model
    if _model is not None:
        return _model
    if not os.path.exists(MODEL_PATH):
        logger.warning("YOLOv8 model not found at %s — using mock detections.", MODEL_PATH)
        return None
    try:
        from ultralytics import YOLO
        _model = YOLO(MODEL_PATH)
        logger.info("YOLOv8 model loaded from %s", MODEL_PATH)
    except Exception as exc:
        logger.error("Failed to load YOLOv8: %s", exc)
        _model = None
    return _model


def run_segmentation(image_rgb: np.ndarray, food_predictions: list[dict]) -> dict:
    """
    Run YOLOv8-seg on the image.

    Args:
        image_rgb: H×W×3 uint8 numpy array (RGB).
        food_predictions: [{class_name, confidence}] from on-device TFLite.

    Returns:
        {
          "plate": {"mask": np.ndarray, "bbox": [x,y,w,h], "area_px": float},
          "foods": [
            {
              "class_name": str,
              "confidence": float,
              "mask": np.ndarray,
              "bbox": [x,y,w,h],
              "area_px": float,
            }
          ]
        }
    """
    model = _load_model()

    if model is not None:
        return _run_real(model, image_rgb, food_predictions)
    else:
        return _mock_detections(image_rgb, food_predictions)


# ── Real inference ────────────────────────────────────────────────────────────

def _run_real(model, image_rgb: np.ndarray, food_predictions: list[dict]) -> dict:
    results = model(image_rgb, verbose=False)[0]
    h, w = image_rgb.shape[:2]

    plate_result = None
    food_results = []

    plate_classes = {
        "plate", "standard_plate", "thali_plate", "thali", 
        "bowl", "katori_bowl", "katori", "tray", "container"
    }

    if results.masks is None:
        return _mock_detections(image_rgb, food_predictions)

    for i, (box, mask_data) in enumerate(
        zip(results.boxes, results.masks.data)
    ):
        cls_id = int(box.cls[0])
        cls_name = model.names[cls_id].lower()
        conf = float(box.conf[0])
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        bbox = [x1, y1, x2 - x1, y2 - y1]

        mask = (mask_data.cpu().numpy() > 0.5).astype(np.uint8)
        area = float(mask.sum())

        entry = {
            "class_name": cls_name,
            "confidence": conf,
            "mask": mask,
            "bbox": bbox,
            "area_px": area,
        }

        if cls_name in plate_classes:
            if plate_result is None or area > plate_result["area_px"]:
                plate_result = entry
        else:
            food_results.append(entry)

    # Merge TFLite on-device predictions for classes YOLO missed
    detected_names = {f["class_name"] for f in food_results}
    for pred in food_predictions:
        name = pred.get("class_name", "")
        if name and name not in detected_names and pred.get("confidence", 0) > 0.5:
            food_results.append(
                _synthetic_food_entry(image_rgb, name, pred["confidence"])
            )

    if plate_result is None:
        plate_result = _synthetic_plate_entry(image_rgb)

    return {"plate": plate_result, "foods": food_results}


# ── Mock / fallback ───────────────────────────────────────────────────────────

def _mock_detections(image_rgb: np.ndarray, food_predictions: list[dict]) -> dict:
    h, w = image_rgb.shape[:2]
    plate = _synthetic_plate_entry(image_rgb)
    foods = []
    if food_predictions:
        for pred in food_predictions[:5]:
            name = pred.get("class_name", "unknown")
            conf = pred.get("confidence", 0.80)
            foods.append(_synthetic_food_entry(image_rgb, name, conf))
    else:
        foods.append(_synthetic_food_entry(image_rgb, "rice_cooked", 0.80))
    return {"plate": plate, "foods": foods}


def _synthetic_plate_entry(image_rgb: np.ndarray) -> dict:
    h, w = image_rgb.shape[:2]
    cx, cy = w // 2, h // 2
    r = min(w, h) // 3
    mask = np.zeros((h, w), dtype=np.uint8)
    Y, X = np.ogrid[:h, :w]
    circle = (X - cx) ** 2 + (Y - cy) ** 2 <= r ** 2
    mask[circle] = 1
    bbox = [cx - r, cy - r, 2 * r, 2 * r]
    return {
        "class_name": "standard_plate",
        "confidence": 1.0,
        "mask": mask,
        "bbox": bbox,
        "area_px": float(mask.sum()),
    }


def _synthetic_food_entry(image_rgb: np.ndarray, name: str, conf: float) -> dict:
    h, w = image_rgb.shape[:2]
    cx, cy = w // 2, h // 2
    r = min(w, h) // 5
    mask = np.zeros((h, w), dtype=np.uint8)
    Y, X = np.ogrid[:h, :w]
    circle = (X - cx) ** 2 + (Y - cy) ** 2 <= r ** 2
    mask[circle] = 1
    bbox = [cx - r, cy - r, 2 * r, 2 * r]
    return {
        "class_name": name,
        "confidence": conf,
        "mask": mask,
        "bbox": bbox,
        "area_px": float(mask.sum()),
    }
