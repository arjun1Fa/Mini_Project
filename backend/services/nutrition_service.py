# Expanded to have typical Indian Foods
INDIAN_FOOD_DB = {
    "idli": {"calories": 140, "protein": 4.0, "carbs": 30.0, "fat": 0.4, "density_g_cm3": 0.8},
    "dosa": {"calories": 160, "protein": 3.0, "carbs": 29.0, "fat": 3.7, "density_g_cm3": 0.6},
    "rice": {"calories": 130, "protein": 2.7, "carbs": 28.0, "fat": 0.3, "density_g_cm3": 0.85},
    "chapati": {"calories": 100, "protein": 3.0, "carbs": 18.0, "fat": 0.5, "density_g_cm3": 0.7},
    "default": {"calories": 150, "protein": 5.0, "carbs": 20.0, "fat": 5.0, "density_g_cm3": 1.0}
}

# Average thickness assumption in cm if depth is not available
DEFAULT_THICKNESS_CM = 2.0 

def calculate_nutrition(food_name, area_cm2):
    """
    Given a food name and estimated 2D area in cm^2, compute volume, weight, and nutrition macros.
    """
    food_data = INDIAN_FOOD_DB.get(food_name.lower(), INDIAN_FOOD_DB["default"])
    
    # 1. Estimate volume (area * average thickness)
    volume_cm3 = area_cm2 * DEFAULT_THICKNESS_CM
    
    # 2. Estimate weight (volume * density)
    weight_g = volume_cm3 * food_data["density_g_cm3"]
    
    # Restrict weight to reasonable bounds just in case
    # This acts as a guard against grossly wrong bbox estimations
    weight_g = max(10, min(weight_g, 1000))
    
    # 3. Calculate macros (values are per 100g)
    multiplier = weight_g / 100.0
    
    calories = food_data["calories"] * multiplier
    protein = food_data["protein"] * multiplier
    carbs = food_data["carbs"] * multiplier
    fat = food_data["fat"] * multiplier
    
    return {
        "food": food_name.capitalize(),
        "weight": f"{int(weight_g)}g",
        "weight_g": weight_g,
        "calories": round(calories),
        "protein": round(protein, 1),
        "carbs": round(carbs, 1),
        "fat": round(fat, 1)
    }
