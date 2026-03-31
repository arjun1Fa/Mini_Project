class MealEntry {
  final String name;
  final String emoji;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime loggedAt;
  final String mealType;

  const MealEntry({
    required this.name,
    required this.emoji,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
    required this.mealType,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(loggedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
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

// ── Sample Data ────────────────────────────────────────

final sampleMeals = [
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
  MealEntry(
    name: 'Chicken Wrap',
    emoji: '🥙',
    calories: 340,
    protein: 28,
    carbs: 30,
    fat: 10,
    loggedAt: DateTime.now().subtract(const Duration(days: 2)),
    mealType: 'Lunch',
  ),
  MealEntry(
    name: 'Scrambled Eggs & Toast',
    emoji: '🥚',
    calories: 310,
    protein: 18,
    carbs: 28,
    fat: 14,
    loggedAt: DateTime.now().subtract(const Duration(days: 3)),
    mealType: 'Breakfast',
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
  MacroGoal(name: 'Carbohydrates', current: 220, goal: 250, colorValue: 0xFFE76F51),
  MacroGoal(name: 'Fats', current: 58, goal: 65, colorValue: 0xFF457B9D),
  MacroGoal(name: 'Fiber', current: 18, goal: 30, colorValue: 0xFFC9A84C),
];

final insights = [
  InsightItem(
    emoji: '💪',
    title: 'Increase Protein Intake',
    body: "You're 15g below your daily protein goal. Try adding lean meats, eggs, or legumes to your next meal.",
    accentColor: 0xFF52B788,
    bgColor: 0xFFD8F3DC,
  ),
  InsightItem(
    emoji: '🥗',
    title: 'Great Vegetable Variety',
    body: "You've eaten 4 different vegetables today. Keep up the excellent variety for optimal micronutrient absorption.",
    accentColor: 0xFF457B9D,
    bgColor: 0xFFDAF0FF,
  ),
  InsightItem(
    emoji: '⚡',
    title: 'Energy Balance',
    body: 'Your calorie intake is well-balanced with your activity level. Maintain this for steady, sustainable progress.',
    accentColor: 0xFFE76F51,
    bgColor: 0xFFFDE8DF,
  ),
  InsightItem(
    emoji: '💧',
    title: 'Hydration Reminder',
    body: "Don't forget to stay hydrated throughout the day. Aim for 8 glasses of water to support digestion.",
    accentColor: 0xFFC9A84C,
    bgColor: 0xFFFDF3D9,
  ),
  InsightItem(
    emoji: '🌾',
    title: 'Add More Fiber',
    body: "You're at 60% of your fiber goal. Include more whole grains, legumes, and fruits to hit your target.",
    accentColor: 0xFF2D6A4F,
    bgColor: 0xFFD8F3DC,
  ),
];
