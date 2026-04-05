"""
Shape model and density lookup table for 60 Indian food classes.
Shape models: spherical_cap | flat_disc | hemisphere | cuboid | cylinder_bowl
Density in g/cm³
"""

SHAPE_DENSITY_TABLE = {
    # ── Rice & Grain Dishes ──────────────────────────────────
    "rice":              {"shape": "spherical_cap",  "density": 0.85},
    "biryani":           {"shape": "spherical_cap",  "density": 0.90},
    "puttu":             {"shape": "cylinder_bowl",  "density": 0.65},
    "idiyappam":         {"shape": "hemisphere",     "density": 0.60},
    "pulao":             {"shape": "spherical_cap",  "density": 0.88},
    "khichdi":           {"shape": "spherical_cap",  "density": 0.92},
    "poha":              {"shape": "flat_disc",       "density": 0.70},
    "upma":              {"shape": "spherical_cap",  "density": 0.85},

    # ── Flatbreads ───────────────────────────────────────────
    "chapathi":          {"shape": "flat_disc",       "density": 0.72},
    "porotta":           {"shape": "flat_disc",       "density": 0.70},
    "appam":             {"shape": "hemisphere",     "density": 0.55},
    "dosa":              {"shape": "flat_disc",       "density": 0.55},
    "roti_chapati":      {"shape": "flat_disc",       "density": 0.72},
    "paratha":           {"shape": "flat_disc",       "density": 0.75},

    # ── South Indian & Kerala Specials ───────────────────────
    "idli":              {"shape": "hemisphere",     "density": 0.65},
    "vada":              {"shape": "hemisphere",     "density": 0.70},
    "sambar":            {"shape": "cylinder_bowl",  "density": 1.01},
    "aviyal":            {"shape": "spherical_cap",  "density": 0.95},
    "kadala_curry":      {"shape": "spherical_cap",  "density": 1.02},
    "coconut_chutney":   {"shape": "cylinder_bowl",  "density": 1.00},
    "green_chutney":     {"shape": "cylinder_bowl",  "density": 1.00},

    # ── Lentils & Curries ─────────────────────────────────────
    "dal_curry":         {"shape": "spherical_cap",  "density": 1.01},
    "chicken_curry":     {"shape": "spherical_cap",  "density": 1.02},
    "beef_curry":        {"shape": "spherical_cap",  "density": 1.04},
    "fish_curry":        {"shape": "spherical_cap",  "density": 1.01},
    "egg_curry":         {"shape": "spherical_cap",  "density": 1.00},

    # ── Fallback ─────────────────────────────────────────────
    "unknown":           {"shape": "spherical_cap",  "density": 0.90},
}


def get_shape_density(food_class: str) -> dict:
    """Return shape model and density for a food class (case-insensitive, underscore-normalised)."""
    key = food_class.lower().replace(" ", "_").replace("-", "_")
    return SHAPE_DENSITY_TABLE.get(key, SHAPE_DENSITY_TABLE["unknown"])


# Plate real-world diameters in cm
PLATE_DIAMETER_CM = {
    "standard": 25.0,
    "thali":    30.0,
    "katori":    9.0,
    "side":     20.0,
}
