// ── Existing UI models (kept for backward compat) ────────────

class MealEntry {
  final String name;
  final String emoji;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime loggedAt;
  final String mealType;
  final String? id;

  const MealEntry({
    required this.name,
    required this.emoji,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
    required this.mealType,
    this.id,
  });

  /// Create from a MealLog API response.
  factory MealEntry.fromMealLog(MealLog log) {
    final items = log.items;
    final String firstName = items.isNotEmpty
        ? (items.first['food_name'] ?? 'Meal').toString()
        : 'Meal';
    return MealEntry(
      id: log.id,
      name: firstName,
      emoji: _emojiFor(firstName),
      calories: log.totalCalories.round(),
      protein: log.totalProteinG,
      carbs: log.totalCarbsG,
      fat: log.totalFatG,
      loggedAt: log.loggedAt,
      mealType: _mealTypeFromTime(log.loggedAt),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(loggedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  static String _emojiFor(String name) {
    final low = name.toLowerCase();
    const map = {
      'roti': '🫓', 'chapati': '🫓', 'rice': '🍚', 'dal': '🍲',
      'chicken': '🍗', 'paneer': '🧀', 'biryani': '🍛', 'dosa': '🥞',
      'idli': '🥟', 'samosa': '📐', 'naan': '🫓', 'curry': '🍛',
      'pizza': '🍕', 'salad': '🥗', 'ramen': '🍜', 'burger': '🍔',
      'pasta': '🍝', 'wrap': '🥙', 'egg': '🥚', 'fish': '🐟',
      'chai': '☕', 'lassi': '🥛', 'veg': '🥦', 'sabzi': '🥦',
    };
    for (final e in map.entries) {
      if (low.contains(e.key)) return e.value;
    }
    return '🍽️';
  }

  static String _mealTypeFromTime(DateTime dt) {
    final hour = dt.hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 15) return 'Lunch';
    if (hour < 18) return 'Snack';
    return 'Dinner';
  }
}

class DailyStats {
  final String day;
  final int calories;
  final bool isToday;

  const DailyStats({
    required this.day,
    required this.calories,
    this.isToday = false,
  });

  double get pct => (calories / 2000).clamp(0.0, 1.0);
}

class MacroGoal {
  final String name;
  final double current;
  final double goal;
  final int colorValue;

  const MacroGoal({
    required this.name,
    required this.current,
    required this.goal,
    required this.colorValue,
  });

  double get pct => (current / goal).clamp(0.0, 1.0);
  String get label => '${current.toInt()} / ${goal.toInt()}g';
}

class InsightItem {
  final String emoji;
  final String title;
  final String body;
  final int accentColor;
  final int bgColor;

  const InsightItem({
    required this.emoji,
    required this.title,
    required this.body,
    required this.accentColor,
    required this.bgColor,
  });
}

// ── API Response Models ─────────────────────────────────────

class BoundingBox {
  final int x;
  final int y;
  final int w;
  final int h;

  const BoundingBox({this.x = 0, this.y = 0, this.w = 0, this.h = 0});

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
      w: (json['w'] as num?)?.toInt() ?? 0,
      h: (json['h'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'w': w, 'h': h};
}

class NutritionInfo {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const NutritionInfo({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'fiber_g': fiberG,
      };

  NutritionInfo scaled(double multiplier) => NutritionInfo(
        calories: calories * multiplier,
        proteinG: proteinG * multiplier,
        carbsG: carbsG * multiplier,
        fatG: fatG * multiplier,
        fiberG: fiberG * multiplier,
      );

  NutritionInfo operator +(NutritionInfo other) => NutritionInfo(
        calories: calories + other.calories,
        proteinG: proteinG + other.proteinG,
        carbsG: carbsG + other.carbsG,
        fatG: fatG + other.fatG,
        fiberG: fiberG + other.fiberG,
      );
}

class AnalyzedFoodItem {
  String foodName;
  final String? foodKey;
  final double confidence;
  double weightG;
  final BoundingBox boundingBox;
  NutritionInfo nutrition;

  AnalyzedFoodItem({
    required this.foodName,
    this.foodKey,
    required this.confidence,
    required this.weightG,
    required this.boundingBox,
    required this.nutrition,
  });

  factory AnalyzedFoodItem.fromJson(Map<String, dynamic> json) {
    return AnalyzedFoodItem(
      foodName: json['food_name'] ?? '',
      foodKey: json['food_key'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      weightG: (json['weight_g'] as num?)?.toDouble() ?? 0,
      boundingBox: BoundingBox.fromJson(
          json['bounding_box'] as Map<String, dynamic>? ?? {}),
      nutrition: NutritionInfo.fromJson(
          json['nutrition'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'food_name': foodName,
        'food_key': foodKey,
        'confidence': confidence,
        'weight_g': weightG,
        'bounding_box': boundingBox.toJson(),
        'nutrition': nutrition.toJson(),
      };

  /// Return a copy with nutrition scaled by the multiplier.
  AnalyzedFoodItem withMultiplier(double m) {
    return AnalyzedFoodItem(
      foodName: foodName,
      foodKey: foodKey,
      confidence: confidence,
      weightG: weightG * m,
      boundingBox: boundingBox,
      nutrition: nutrition.scaled(m),
    );
  }
}

class AnalyzeResult {
  final List<AnalyzedFoodItem> items;
  final NutritionInfo total;
  final int processingTimeMs;
  final bool isOffline;
  final String? imagePath;

  const AnalyzeResult({
    required this.items,
    required this.total,
    this.processingTimeMs = 0,
    this.isOffline = false,
    this.imagePath,
  });

  factory AnalyzeResult.fromJson(Map<String, dynamic> json,
      {String? imagePath}) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => AnalyzedFoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return AnalyzeResult(
      items: itemsList,
      total:
          NutritionInfo.fromJson(json['total'] as Map<String, dynamic>? ?? {}),
      processingTimeMs: (json['processing_time_ms'] as num?)?.toInt() ?? 0,
      imagePath: imagePath,
    );
  }

  /// Create a new AnalyzeResult with all items scaled.
  AnalyzeResult withMultiplier(double m) {
    final scaledItems = items.map((i) => i.withMultiplier(m)).toList();
    final scaledTotal = total.scaled(m);
    return AnalyzeResult(
      items: scaledItems,
      total: scaledTotal,
      processingTimeMs: processingTimeMs,
      isOffline: isOffline,
      imagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'total': total.toJson(),
        'processing_time_ms': processingTimeMs,
      };
}

// ── Meal Log (from /api/meals/history) ──────────────────────

class MealLog {
  final String id;
  final DateTime loggedAt;
  final String imageUrl;
  final List<dynamic> items;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double totalFiberG;

  const MealLog({
    required this.id,
    required this.loggedAt,
    this.imageUrl = '',
    this.items = const [],
    this.totalCalories = 0,
    this.totalProteinG = 0,
    this.totalCarbsG = 0,
    this.totalFatG = 0,
    this.totalFiberG = 0,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] ?? '',
      loggedAt: DateTime.tryParse(json['logged_at'] ?? '') ?? DateTime.now(),
      imageUrl: json['image_url'] ?? '',
      items: json['items'] as List<dynamic>? ?? [],
      totalCalories: (json['total_calories'] as num?)?.toDouble() ?? 0,
      totalProteinG: (json['total_protein_g'] as num?)?.toDouble() ?? 0,
      totalCarbsG: (json['total_carbs_g'] as num?)?.toDouble() ?? 0,
      totalFatG: (json['total_fat_g'] as num?)?.toDouble() ?? 0,
      totalFiberG: (json['total_fiber_g'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── User Profile ────────────────────────────────────────────

class UserProfile {
  final String? fullName;
  final int dailyGoalKcal;
  final String plateType;
  final String units;

  const UserProfile({
    this.fullName,
    this.dailyGoalKcal = 2000,
    this.plateType = 'standard',
    this.units = 'grams',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'],
      dailyGoalKcal: (json['daily_goal_kcal'] as num?)?.toInt() ?? 2000,
      plateType: json['plate_type'] ?? 'standard',
      units: json['units'] ?? 'grams',
    );
  }

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'daily_goal_kcal': dailyGoalKcal,
        'plate_type': plateType,
        'units': units,
      };

  UserProfile copyWith({
    String? fullName,
    int? dailyGoalKcal,
    String? plateType,
    String? units,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      dailyGoalKcal: dailyGoalKcal ?? this.dailyGoalKcal,
      plateType: plateType ?? this.plateType,
      units: units ?? this.units,
    );
  }
}

// ── Food Search Result ──────────────────────────────────────

class FoodSearchResult {
  final String foodName;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const FoodSearchResult({
    required this.foodName,
    this.caloriesPer100g = 0,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
  });

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    return FoodSearchResult(
      foodName: json['food_name'] ?? '',
      caloriesPer100g:
          (json['calories_per_100g'] as num?)?.toDouble() ?? 0,
      proteinPer100g:
          (json['protein_per_100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (json['fat_per_100g'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── Sample Data (kept for InsightsScreen etc.) ──────────────

final sampleMeals = <MealEntry>[
  MealEntry(
    name: 'Margherita Pizza',
    emoji: '🍕',
    calories: 285,
    protein: 12,
    carbs: 36,
    fat: 8,
    loggedAt: DateTime.now().subtract(const Duration(hours: 2)),
    mealType: 'Lunch',
  ),
  MealEntry(
    name: 'Caesar Salad',
    emoji: '🥗',
    calories: 180,
    protein: 8,
    carbs: 14,
    fat: 12,
    loggedAt: DateTime.now().subtract(const Duration(hours: 5)),
    mealType: 'Lunch',
  ),
  MealEntry(
    name: 'Chicken Ramen',
    emoji: '🍜',
    calories: 420,
    protein: 22,
    carbs: 52,
    fat: 15,
    loggedAt: DateTime.now().subtract(const Duration(hours: 26)),
    mealType: 'Dinner',
  ),
];

final weeklyData = [
  DailyStats(day: 'Mon', calories: 1820),
  DailyStats(day: 'Tue', calories: 2100),
  DailyStats(day: 'Wed', calories: 1600),
  DailyStats(day: 'Thu', calories: 2200),
  DailyStats(day: 'Fri', calories: 1900),
  DailyStats(day: 'Sat', calories: 2350),
  DailyStats(day: 'Sun', calories: 1847, isToday: true),
];

final macroGoals = [
  MacroGoal(name: 'Protein', current: 68, goal: 83, colorValue: 0xFF52B788),
  MacroGoal(
      name: 'Carbohydrates', current: 220, goal: 250, colorValue: 0xFFE76F51),
  MacroGoal(name: 'Fats', current: 58, goal: 65, colorValue: 0xFF457B9D),
  MacroGoal(name: 'Fiber', current: 18, goal: 30, colorValue: 0xFFC9A84C),
];

final insights = [
  InsightItem(
    emoji: '💪',
    title: 'Increase Protein Intake',
    body:
        "You're 15g below your daily protein goal. Try adding lean meats, eggs, or legumes to your next meal.",
    accentColor: 0xFF52B788,
    bgColor: 0xFFD8F3DC,
  ),
  InsightItem(
    emoji: '🥗',
    title: 'Great Vegetable Variety',
    body:
        "You've eaten 4 different vegetables today. Keep up the excellent variety for optimal micronutrient absorption.",
    accentColor: 0xFF457B9D,
    bgColor: 0xFFDAF0FF,
  ),
  InsightItem(
    emoji: '⚡',
    title: 'Energy Balance',
    body:
        'Your calorie intake is well-balanced with your activity level. Maintain this for steady, sustainable progress.',
    accentColor: 0xFFE76F51,
    bgColor: 0xFFFDE8DF,
  ),
  InsightItem(
    emoji: '💧',
    title: 'Hydration Reminder',
    body:
        "Don't forget to stay hydrated throughout the day. Aim for 8 glasses of water to support digestion.",
    accentColor: 0xFFC9A84C,
    bgColor: 0xFFFDF3D9,
  ),
  InsightItem(
    emoji: '🌾',
    title: 'Add More Fiber',
    body:
        "You're at 60% of your fiber goal. Include more whole grains, legumes, and fruits to hit your target.",
    accentColor: 0xFF2D6A4F,
    bgColor: 0xFFD8F3DC,
  ),
];
