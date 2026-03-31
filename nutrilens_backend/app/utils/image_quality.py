"""
Image quality checks: blur detection (Laplacian variance) + brightness check.
"""
import cv2
import numpy as np


def laplacian_variance(image_bgr: np.ndarray) -> float:
    """Return Laplacian variance — lower = blurrier."""
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    return float(cv2.Laplacian(gray, cv2.CV_64F).var())


def mean_brightness(image_bgr: np.ndarray) -> float:
    """Return mean V-channel brightness (0–255)."""
    hsv = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2HSV)
    return float(hsv[:, :, 2].mean())


def check_image_quality(
    image_bgr: np.ndarray,
    blur_threshold: float = 100.0,
    brightness_threshold: float = 50.0,
) -> tuple[bool, str]:
    """
    Returns (is_ok, error_code).
    error_code is empty string if quality passes.
    """
    lv = laplacian_variance(image_bgr)
    if lv < blur_threshold:
        return False, "image_too_blurry"

    mb = mean_brightness(image_bgr)
    if mb < brightness_threshold:
        return False, "image_too_dark"

    return True, ""
