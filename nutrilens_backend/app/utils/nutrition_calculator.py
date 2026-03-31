"""
Nutrition scaling: multiply per-100g values by actual weight.
"""


def scale_nutrition(nutrition_per_100g: dict, weight_g: float) -> dict:
    """
    Scale nutrition facts from per-100g to actual weight.

    Args:
        nutrition_per_100g: {calories, protein_g, carbs_g, fat_g, fiber_g,
                             sodium_mg, calcium_mg, iron_mg}
        weight_g: Actual estimated weight.

    Returns:
        Scaled nutrition dict.
    """
    factor = weight_g / 100.0
    return {
        "calories":    round(nutrition_per_100g.get("calories_per_100g", 0) * factor, 1),
        "protein_g":   round(nutrition_per_100g.get("protein_per_100g", 0) * factor, 2),
        "carbs_g":     round(nutrition_per_100g.get("carbs_per_100g", 0) * factor, 2),
        "fat_g":       round(nutrition_per_100g.get("fat_per_100g", 0) * factor, 2),
        "fiber_g":     round(nutrition_per_100g.get("fiber_per_100g", 0) * factor, 2),
        "sodium_mg":   round(nutrition_per_100g.get("sodium_per_100g", 0) * factor, 1),
        "calcium_mg":  round(nutrition_per_100g.get("calcium_per_100g", 0) * factor, 1),
        "iron_mg":     round(nutrition_per_100g.get("iron_per_100g", 0) * factor, 2),
    }


def sum_nutrition(items: list[dict]) -> dict:
    """Sum nutrition across all items."""
    totals = {
        "calories": 0.0, "protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0,
        "fiber_g": 0.0, "sodium_mg": 0.0, "calcium_mg": 0.0, "iron_mg": 0.0,
    }
    for item in items:
        n = item.get("nutrition", {})
        for key in totals:
            totals[key] = round(totals[key] + n.get(key, 0.0), 2)
    return totals


# ── Fallback IFCT 2017 values for common items (used when Supabase is unreachable) ──

FALLBACK_NUTRITION = {
    "rice_cooked":          {"calories_per_100g": 130, "protein_per_100g": 2.7, "carbs_per_100g": 28.2, "fat_per_100g": 0.3, "fiber_per_100g": 0.4, "sodium_per_100g": 1,  "calcium_per_100g": 3,  "iron_per_100g": 0.2},
    "roti_chapati":         {"calories_per_100g": 297, "protein_per_100g": 9.9, "carbs_per_100g": 59.4, "fat_per_100g": 3.7, "fiber_per_100g": 1.9, "sodium_per_100g": 4,  "calcium_per_100g": 23, "iron_per_100g": 2.7},
    "dal_tadka":            {"calories_per_100g": 119, "protein_per_100g": 6.8, "carbs_per_100g": 16.2, "fat_per_100g": 3.0, "fiber_per_100g": 3.5, "sodium_per_100g": 2,  "calcium_per_100g": 25, "iron_per_100g": 1.8},
    "paneer":               {"calories_per_100g": 296, "protein_per_100g": 18.3,"carbs_per_100g": 1.2,  "fat_per_100g": 23.5,"fiber_per_100g": 0.0, "sodium_per_100g": 20, "calcium_per_100g": 200,"iron_per_100g": 0.3},
    "idli":                 {"calories_per_100g": 58,  "protein_per_100g": 1.9, "carbs_per_100g": 11.4, "fat_per_100g": 0.4, "fiber_per_100g": 0.5, "sodium_per_100g": 30, "calcium_per_100g": 11, "iron_per_100g": 0.4},
    "dosa":                 {"calories_per_100g": 168, "protein_per_100g": 3.7, "carbs_per_100g": 25.3, "fat_per_100g": 5.8, "fiber_per_100g": 0.7, "sodium_per_100g": 65, "calcium_per_100g": 18, "iron_per_100g": 0.8},
    "biryani":              {"calories_per_100g": 163, "protein_per_100g": 7.2, "carbs_per_100g": 24.5, "fat_per_100g": 4.5, "fiber_per_100g": 0.8, "sodium_per_100g": 12, "calcium_per_100g": 20, "iron_per_100g": 0.9},
    "sambar":               {"calories_per_100g": 55,  "protein_per_100g": 2.8, "carbs_per_100g": 7.5,  "fat_per_100g": 1.5, "fiber_per_100g": 2.0, "sodium_per_100g": 18, "calcium_per_100g": 30, "iron_per_100g": 1.0},
    "chole":                {"calories_per_100g": 164, "protein_per_100g": 8.9, "carbs_per_100g": 27.4, "fat_per_100g": 2.6, "fiber_per_100g": 7.6, "sodium_per_100g": 10, "calcium_per_100g": 49, "iron_per_100g": 2.9},
    "butter_chicken":       {"calories_per_100g": 150, "protein_per_100g": 11.0,"carbs_per_100g": 7.0,  "fat_per_100g": 8.5, "fiber_per_100g": 1.0, "sodium_per_100g": 35, "calcium_per_100g": 30, "iron_per_100g": 1.2},
    "palak_paneer":         {"calories_per_100g": 156, "protein_per_100g": 7.8, "carbs_per_100g": 6.2,  "fat_per_100g": 11.2,"fiber_per_100g": 2.3, "sodium_per_100g": 22, "calcium_per_100g": 185,"iron_per_100g": 2.1},
    "paratha":              {"calories_per_100g": 319, "protein_per_100g": 7.0, "carbs_per_100g": 43.2, "fat_per_100g": 13.0,"fiber_per_100g": 2.1, "sodium_per_100g": 5,  "calcium_per_100g": 30, "iron_per_100g": 2.5},
    "rajma":                {"calories_per_100g": 124, "protein_per_100g": 7.0, "carbs_per_100g": 22.8, "fat_per_100g": 0.6, "fiber_per_100g": 6.4, "sodium_per_100g": 5,  "calcium_per_100g": 45, "iron_per_100g": 2.5},
    "poha":                 {"calories_per_100g": 110, "protein_per_100g": 2.4, "carbs_per_100g": 22.5, "fat_per_100g": 0.8, "fiber_per_100g": 0.6, "sodium_per_100g": 2,  "calcium_per_100g": 12, "iron_per_100g": 0.4},
    "upma":                 {"calories_per_100g": 126, "protein_per_100g": 2.8, "carbs_per_100g": 21.0, "fat_per_100g": 3.5, "fiber_per_100g": 1.2, "sodium_per_100g": 15, "calcium_per_100g": 14, "iron_per_100g": 0.7},
    "chicken_curry":        {"calories_per_100g": 143, "protein_per_100g": 13.5,"carbs_per_100g": 5.4,  "fat_per_100g": 8.0, "fiber_per_100g": 0.8, "sodium_per_100g": 28, "calcium_per_100g": 25, "iron_per_100g": 1.4},
    "gulab_jamun":          {"calories_per_100g": 337, "protein_per_100g": 4.0, "carbs_per_100g": 51.3, "fat_per_100g": 12.8,"fiber_per_100g": 0.2, "sodium_per_100g": 12, "calcium_per_100g": 90, "iron_per_100g": 0.8},
    "samosa":               {"calories_per_100g": 262, "protein_per_100g": 5.0, "carbs_per_100g": 30.2, "fat_per_100g": 13.8,"fiber_per_100g": 2.0, "sodium_per_100g": 30, "calcium_per_100g": 18, "iron_per_100g": 1.5},
    "unknown":              {"calories_per_100g": 150, "protein_per_100g": 5.0, "carbs_per_100g": 20.0, "fat_per_100g": 5.0, "fiber_per_100g": 1.5, "sodium_per_100g": 10, "calcium_per_100g": 20, "iron_per_100g": 1.0},
}
