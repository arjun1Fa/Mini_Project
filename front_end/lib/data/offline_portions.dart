/// Hardcoded typical Indian food portion weights for offline mode.
/// All nutrition values are per standard serving (not per 100g).
class OfflinePortions {
  static const List<Map<String, dynamic>> fallbackItems = [
    {
      'food_name': 'Roti / Chapati',
      'food_key': 'roti_chapati',
      'weight_g': 40.0,
      'nutrition': {
        'calories': 119,
        'protein_g': 4.0,
        'carbs_g': 23.8,
        'fat_g': 1.5,
        'fiber_g': 0.8,
      },
    },
    {
      'food_name': 'Rice (Cooked)',
      'food_key': 'rice_cooked',
      'weight_g': 150.0,
      'nutrition': {
        'calories': 195,
        'protein_g': 4.1,
        'carbs_g': 42.3,
        'fat_g': 0.5,
        'fiber_g': 0.6,
      },
    },
    {
      'food_name': 'Dal Tadka',
      'food_key': 'dal_tadka',
      'weight_g': 100.0,
      'nutrition': {
        'calories': 119,
        'protein_g': 6.8,
        'carbs_g': 16.2,
        'fat_g': 3.0,
        'fiber_g': 3.5,
      },
    },
    {
      'food_name': 'Sabzi (Mixed Veg)',
      'food_key': 'mixed_veg_curry',
      'weight_g': 80.0,
      'nutrition': {
        'calories': 58,
        'protein_g': 1.6,
        'carbs_g': 7.6,
        'fat_g': 2.4,
        'fiber_g': 2.0,
      },
    },
    {
      'food_name': 'Idli (×2)',
      'food_key': 'idli',
      'weight_g': 100.0,
      'nutrition': {
        'calories': 58,
        'protein_g': 1.9,
        'carbs_g': 11.4,
        'fat_g': 0.4,
        'fiber_g': 0.5,
      },
    },
    {
      'food_name': 'Dosa',
      'food_key': 'dosa',
      'weight_g': 85.0,
      'nutrition': {
        'calories': 143,
        'protein_g': 3.1,
        'carbs_g': 21.5,
        'fat_g': 4.9,
        'fiber_g': 0.6,
      },
    },
    {
      'food_name': 'Paratha',
      'food_key': 'paratha',
      'weight_g': 70.0,
      'nutrition': {
        'calories': 223,
        'protein_g': 4.9,
        'carbs_g': 30.2,
        'fat_g': 9.1,
        'fiber_g': 1.5,
      },
    },
    {
      'food_name': 'Samosa',
      'food_key': 'samosa',
      'weight_g': 50.0,
      'nutrition': {
        'calories': 131,
        'protein_g': 2.5,
        'carbs_g': 15.1,
        'fat_g': 6.9,
        'fiber_g': 1.0,
      },
    },
    {
      'food_name': 'Biryani',
      'food_key': 'biryani',
      'weight_g': 200.0,
      'nutrition': {
        'calories': 326,
        'protein_g': 14.4,
        'carbs_g': 49.0,
        'fat_g': 9.0,
        'fiber_g': 1.6,
      },
    },
    {
      'food_name': 'Chicken Curry',
      'food_key': 'chicken_curry',
      'weight_g': 120.0,
      'nutrition': {
        'calories': 172,
        'protein_g': 16.2,
        'carbs_g': 6.5,
        'fat_g': 9.6,
        'fiber_g': 1.0,
      },
    },
    {
      'food_name': 'Paneer',
      'food_key': 'paneer',
      'weight_g': 75.0,
      'nutrition': {
        'calories': 222,
        'protein_g': 13.7,
        'carbs_g': 0.9,
        'fat_g': 17.6,
        'fiber_g': 0.0,
      },
    },
    {
      'food_name': 'Naan',
      'food_key': 'naan',
      'weight_g': 60.0,
      'nutrition': {
        'calories': 186,
        'protein_g': 5.3,
        'carbs_g': 29.4,
        'fat_g': 5.1,
        'fiber_g': 1.2,
      },
    },
    {
      'food_name': 'Puri',
      'food_key': 'puri',
      'weight_g': 30.0,
      'nutrition': {
        'calories': 98,
        'protein_g': 2.1,
        'carbs_g': 12.9,
        'fat_g': 4.2,
        'fiber_g': 0.5,
      },
    },
    {
      'food_name': 'Chai',
      'food_key': 'chai',
      'weight_g': 150.0,
      'nutrition': {
        'calories': 60,
        'protein_g': 2.3,
        'carbs_g': 8.3,
        'fat_g': 2.3,
        'fiber_g': 0.0,
      },
    },
    {
      'food_name': 'Lassi',
      'food_key': 'lassi',
      'weight_g': 200.0,
      'nutrition': {
        'calories': 150,
        'protein_g': 7.0,
        'carbs_g': 20.0,
        'fat_g': 5.0,
        'fiber_g': 0.0,
      },
    },
  ];

  /// Look up a fallback item by food key (snake_case).
  static Map<String, dynamic>? findByKey(String key) {
    final normalized = key.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    for (final item in fallbackItems) {
      if (item['food_key'] == normalized) return item;
    }
    return null;
  }

  /// Returns all fallback items formatted as AnalyzedFoodItem-compatible maps.
  static List<Map<String, dynamic>> asAnalyzeItems() {
    return fallbackItems.map((item) {
      return {
        'food_name': item['food_name'],
        'food_key': item['food_key'],
        'confidence': 0.0,
        'weight_g': item['weight_g'],
        'bounding_box': {'x': 0, 'y': 0, 'w': 0, 'h': 0},
        'nutrition': item['nutrition'],
      };
    }).toList();
  }
}
