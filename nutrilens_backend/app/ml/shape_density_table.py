"""
Shape model and density lookup table for 60 Indian food classes.
Shape models: spherical_cap | flat_disc | hemisphere | cuboid | cylinder_bowl
Density in g/cm³
"""

SHAPE_DENSITY_TABLE = {
    # ── Rice & Grain Dishes ──────────────────────────────────
    "rice_cooked":       {"shape": "spherical_cap",  "density": 0.85},
    "biryani":           {"shape": "spherical_cap",  "density": 0.90},
    "pulao":             {"shape": "spherical_cap",  "density": 0.88},
    "khichdi":           {"shape": "spherical_cap",  "density": 0.92},
    "poha":              {"shape": "flat_disc",       "density": 0.70},
    "upma":              {"shape": "spherical_cap",  "density": 0.85},
    "pongal":            {"shape": "spherical_cap",  "density": 0.90},
    "fried_rice":        {"shape": "spherical_cap",  "density": 0.88},

    # ── Flatbreads ───────────────────────────────────────────
    "roti_chapati":      {"shape": "flat_disc",       "density": 0.72},
    "paratha":           {"shape": "flat_disc",       "density": 0.75},
    "puri":              {"shape": "flat_disc",       "density": 0.60},
    "bhatura":           {"shape": "hemisphere",     "density": 0.55},
    "naan":              {"shape": "flat_disc",       "density": 0.68},
    "kulcha":            {"shape": "flat_disc",       "density": 0.70},
    "dosa":              {"shape": "flat_disc",       "density": 0.55},
    "uttapam":           {"shape": "flat_disc",       "density": 0.65},

    # ── South Indian ─────────────────────────────────────────
    "idli":              {"shape": "hemisphere",     "density": 0.65},
    "vada":              {"shape": "hemisphere",     "density": 0.70},
    "sambar":            {"shape": "cylinder_bowl",  "density": 1.01},
    "coconut_chutney":   {"shape": "cylinder_bowl",  "density": 1.00},
    "rasam":             {"shape": "cylinder_bowl",  "density": 1.00},

    # ── Lentils & Pulses ─────────────────────────────────────
    "dal_tadka":         {"shape": "spherical_cap",  "density": 1.01},
    "dal_makhani":       {"shape": "spherical_cap",  "density": 1.03},
    "chana_masala":      {"shape": "spherical_cap",  "density": 1.02},
    "chole":             {"shape": "spherical_cap",  "density": 1.02},
    "rajma":             {"shape": "spherical_cap",  "density": 1.02},
    "moong_dal":         {"shape": "spherical_cap",  "density": 1.00},
    "sambhar_dal":       {"shape": "spherical_cap",  "density": 1.01},

    # ── Vegetables (Sabzi / Curry) ───────────────────────────
    "aloo_sabzi":        {"shape": "spherical_cap",  "density": 0.95},
    "palak_paneer":      {"shape": "spherical_cap",  "density": 0.98},
    "paneer_butter_masala": {"shape": "spherical_cap","density": 1.00},
    "paneer":            {"shape": "cuboid",         "density": 1.05},
    "matar_paneer":      {"shape": "spherical_cap",  "density": 0.97},
    "baingan_bharta":    {"shape": "spherical_cap",  "density": 0.94},
    "gobi_sabzi":        {"shape": "spherical_cap",  "density": 0.80},
    "bhindi_masala":     {"shape": "spherical_cap",  "density": 0.88},
    "aloo_gobi":         {"shape": "spherical_cap",  "density": 0.90},
    "mixed_veg_curry":   {"shape": "spherical_cap",  "density": 0.93},
    "saag":              {"shape": "spherical_cap",  "density": 0.96},

    # ── Non-Vegetarian ────────────────────────────────────────
    "chicken_curry":     {"shape": "spherical_cap",  "density": 1.02},
    "butter_chicken":    {"shape": "spherical_cap",  "density": 1.03},
    "mutton_curry":      {"shape": "spherical_cap",  "density": 1.04},
    "fish_curry":        {"shape": "spherical_cap",  "density": 1.01},
    "egg_curry":         {"shape": "spherical_cap",  "density": 1.00},
    "tandoori_chicken":  {"shape": "cuboid",         "density": 0.95},
    "seekh_kebab":       {"shape": "cuboid",         "density": 0.92},

    # ── Snacks & Street Food ─────────────────────────────────
    "samosa":            {"shape": "hemisphere",     "density": 0.68},
    "pakora":            {"shape": "hemisphere",     "density": 0.65},
    "pani_puri":         {"shape": "hemisphere",     "density": 0.55},
    "bhel_puri":         {"shape": "spherical_cap",  "density": 0.60},
    "aloo_tikki":        {"shape": "flat_disc",       "density": 0.78},
    "dhokla":            {"shape": "cuboid",         "density": 0.60},
    "kachori":           {"shape": "hemisphere",     "density": 0.65},

    # ── Desserts ─────────────────────────────────────────────
    "gulab_jamun":       {"shape": "hemisphere",     "density": 1.10},
    "kheer":             {"shape": "cylinder_bowl",  "density": 1.05},
    "halwa":             {"shape": "spherical_cap",  "density": 1.08},
    "jalebi":            {"shape": "flat_disc",       "density": 1.12},
    "rasgulla":          {"shape": "hemisphere",     "density": 1.08},

    # ── Drinks / Liquids ─────────────────────────────────────
    "lassi":             {"shape": "cylinder_bowl",  "density": 1.02},
    "chai":              {"shape": "cylinder_bowl",  "density": 1.00},

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
