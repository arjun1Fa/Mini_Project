"""
Depth Anything V2 (Small) inference handler.
Falls back to a heuristic when the model file is absent.
"""
import os
import logging
import numpy as np

logger = logging.getLogger(__name__)

_model = None
_transform = None
MODEL_PATH = os.path.join(
    os.getenv("MODEL_DIR", "models"), "depth_anything_v2_small.pth"
)
INPUT_SIZE = 518  # Depth Anything V2 canonical input size


def _load_model():
    global _model, _transform
    if _model is not None:
        return _model
    if not os.path.exists(MODEL_PATH):
        logger.warning(
            "Depth Anything V2 model not found at %s — using heuristic depth.", MODEL_PATH
        )
        return None
    try:
        import torch
        from depth_anything_v2.dpt import DepthAnythingV2
        from torchvision import transforms

        device = "cuda" if torch.cuda.is_available() else "cpu"
        cfg = {"encoder": "vits", "features": 64, "out_channels": [48, 96, 192, 384]}
        _model = DepthAnythingV2(**cfg)
        state = torch.load(MODEL_PATH, map_location=device)
        _model.load_state_dict(state)
        _model.eval().to(device)

        _transform = transforms.Compose(
            [
                transforms.ToPILImage(),
                transforms.Resize((INPUT_SIZE, INPUT_SIZE)),
                transforms.ToTensor(),
                transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
            ]
        )
        logger.info("Depth Anything V2 loaded.")
    except Exception as exc:
        logger.error("Failed to load Depth Anything V2: %s", exc)
        _model = None
    return _model


def estimate_heights(
    image_rgb: np.ndarray,
    food_masks: list[np.ndarray],
    pixel_per_cm: float,
) -> list[float]:
    """
    Estimate food item heights in cm.

    Args:
        image_rgb: H×W×3 uint8 numpy array (RGB).
        food_masks: Binary masks for each food item.
        pixel_per_cm: Calibration factor.

    Returns:
        List of estimated heights in cm, one per mask.
    """
    model = _load_model()
    if model is not None:
        depth_map = _run_real_depth(model, image_rgb)
    else:
        depth_map = _heuristic_depth(image_rgb)

    heights = []
    for mask in food_masks:
        if mask.sum() == 0:
            heights.append(3.0)
            continue
        # Extract depth values inside the mask
        depth_vals = depth_map[mask.astype(bool)]
        # Depth Anything V2 gives inverse-depth: larger = closer (higher food)
        h_depth = float(np.percentile(depth_vals, 90) - np.percentile(depth_vals, 10))
        # Scale to cm using pixel_per_cm anchor
        # Assume 1 depth unit ≈ 1/pixel_per_cm cm (rough linear anchor)
        height_cm = h_depth / max(pixel_per_cm, 1.0) * 10.0
        height_cm = max(0.5, min(height_cm, 12.0))
        heights.append(height_cm)

    return heights


# ── Real inference ────────────────────────────────────────────────────────────

def _run_real_depth(model, image_rgb: np.ndarray) -> np.ndarray:
    import torch

    device = next(model.parameters()).device
    tensor = _transform(image_rgb).unsqueeze(0).to(device)
    with torch.no_grad():
        depth = model(tensor)
    depth_np = depth.squeeze().cpu().numpy()
    # Resize back to original image size
    import cv2
    h, w = image_rgb.shape[:2]
    depth_np = cv2.resize(depth_np, (w, h), interpolation=cv2.INTER_LINEAR)
    return depth_np


# ── Heuristic fallback ────────────────────────────────────────────────────────

def _heuristic_depth(image_rgb: np.ndarray) -> np.ndarray:
    """
    Simple brightness-based heuristic: brighter centre pixels → higher (closer).
    Used only when the model file is unavailable.
    """
    import cv2

    gray = cv2.cvtColor(image_rgb, cv2.COLOR_RGB2GRAY).astype(np.float32)
    # Normalise to [0, 1]
    gray = (gray - gray.min()) / (gray.max() - gray.min() + 1e-6)
    return gray
