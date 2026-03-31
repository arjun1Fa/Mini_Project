"""
Geometric volume estimation for food items.
Formulas reference: NutriLens spec.
"""
import math
from .shape_density_table import get_shape_density


def _spherical_cap_volume(area_cm2: float, height_cm: float) -> float:
    """V = (π × h / 6) × (3a² + h²), a = sqrt(area / π)"""
    a = math.sqrt(area_cm2 / math.pi)
    return (math.pi * height_cm / 6.0) * (3 * a ** 2 + height_cm ** 2)


def _flat_disc_volume(area_cm2: float, height_cm: float) -> float:
    """V = area × height (thin slab)"""
    return area_cm2 * max(height_cm, 0.5)  # min 0.5 cm thickness


def _hemisphere_volume(area_cm2: float) -> float:
    """V = (2/3) × π × r³, r = sqrt(area / π)"""
    r = math.sqrt(area_cm2 / math.pi)
    return (2.0 / 3.0) * math.pi * r ** 3


def _cuboid_volume(area_cm2: float, height_cm: float) -> float:
    """V = area × height"""
    return area_cm2 * max(height_cm, 1.0)


def _cylinder_bowl_volume(area_cm2: float, height_cm: float) -> float:
    """V = area × height (treat as filled cylinder)"""
    return area_cm2 * max(height_cm, 2.0)


def estimate_weight(
    food_class: str,
    area_pixels: float,
    pixel_per_cm: float,
    estimated_height_cm: float,
) -> float:
    """
    Estimate food weight in grams from pixel measurements.

    Args:
        food_class: Normalised food class name.
        area_pixels: Segmentation mask area in pixels.
        pixel_per_cm: Pixels per centimetre derived from plate detection.
        estimated_height_cm: Height from Depth Anything V2 (in cm).

    Returns:
        Estimated weight in grams.
    """
    if pixel_per_cm <= 0:
        pixel_per_cm = 20.0  # safe fallback

    area_cm2 = area_pixels / (pixel_per_cm ** 2)
    info = get_shape_density(food_class)
    shape = info["shape"]
    density = info["density"]

    if shape == "spherical_cap":
        vol = _spherical_cap_volume(area_cm2, estimated_height_cm)
    elif shape == "flat_disc":
        vol = _flat_disc_volume(area_cm2, estimated_height_cm)
    elif shape == "hemisphere":
        vol = _hemisphere_volume(area_cm2)
    elif shape == "cuboid":
        vol = _cuboid_volume(area_cm2, estimated_height_cm)
    elif shape == "cylinder_bowl":
        vol = _cylinder_bowl_volume(area_cm2, estimated_height_cm)
    else:
        vol = _spherical_cap_volume(area_cm2, estimated_height_cm)

    weight_g = vol * density
    # Clamp to realistic bounds
    return max(5.0, min(weight_g, 800.0))
