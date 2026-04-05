import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'api_provider.dart';

/// State for paginated meal history.
class MealHistoryState {
  final List<MealLog> meals;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const MealHistoryState({
    this.meals = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  MealHistoryState copyWith({
    List<MealLog>? meals,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return MealHistoryState(
      meals: meals ?? this.meals,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }

  /// Compute weekly calorie data from meals (last 7 days).
  List<DailyStats> get weeklyCalories {
    final now = DateTime.now();
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <DailyStats>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayCals = meals
          .where((m) =>
              m.loggedAt.isAfter(dayStart) && m.loggedAt.isBefore(dayEnd))
          .fold<double>(0, (sum, m) => sum + m.totalCalories);

      result.add(DailyStats(
        day: dayNames[day.weekday - 1],
        calories: dayCals.round(),
        isToday: i == 0,
      ));
    }
    return result;
  }

  /// Today's total macros.
  MacroGoal proteinGoal(double goalG) {
    final today = _todayMeals;
    final current = today.fold<double>(0, (s, m) => s + m.totalProteinG);
    return MacroGoal(
        name: 'Protein', current: current, goal: goalG, colorValue: 0xFF52B788);
  }

  MacroGoal carbsGoal(double goalG) {
    final today = _todayMeals;
    final current = today.fold<double>(0, (s, m) => s + m.totalCarbsG);
    return MacroGoal(
        name: 'Carbs',
        current: current,
        goal: goalG,
        colorValue: 0xFFE76F51);
  }

  MacroGoal fatGoal(double goalG) {
    final today = _todayMeals;
    final current = today.fold<double>(0, (s, m) => s + m.totalFatG);
    return MacroGoal(
        name: 'Fats', current: current, goal: goalG, colorValue: 0xFF457B9D);
  }

  MacroGoal fiberGoal(double goalG) {
    final today = _todayMeals;
    final current = today.fold<double>(0, (s, m) => s + m.totalFiberG);
    return MacroGoal(
        name: 'Fiber', current: current, goal: goalG, colorValue: 0xFFC9A84C);
  }

  List<MealLog> get _todayMeals {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    return meals.where((m) => m.loggedAt.isAfter(dayStart)).toList();
  }

  double get todayCalories {
    return _todayMeals.fold<double>(0, (s, m) => s + m.totalCalories);
  }

  double get todayProtein {
    return _todayMeals.fold<double>(0, (s, m) => s + m.totalProteinG);
  }

  int get mealCountThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return meals.where((m) => m.loggedAt.isAfter(start)).length;
  }
}

/// Notifier for meal history with pagination.
class MealHistoryNotifier extends StateNotifier<MealHistoryState> {
  final Ref _ref;

  MealHistoryNotifier(this._ref) : super(const MealHistoryState());

  /// Load the first page of meal history.
  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final api = _ref.read(apiServiceProvider);
      final now = DateTime.now();
      final startDate =
          now.subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
      final endDate = now.toIso8601String().split('T')[0];

      final result = await api.getMealHistory(
        startDate: startDate,
        endDate: endDate,
        page: 1,
        pageSize: 50,
      );

      final data = (result['data'] as List<dynamic>? ?? [])
          .map((e) => MealLog.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (result['count'] as num?)?.toInt() ?? 0;

      state = state.copyWith(
        meals: data,
        isLoading: false,
        currentPage: 1,
        hasMore: data.length < total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load the next page.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final api = _ref.read(apiServiceProvider);
      final nextPage = state.currentPage + 1;
      final now = DateTime.now();
      final startDate =
          now.subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
      final endDate = now.toIso8601String().split('T')[0];

      final result = await api.getMealHistory(
        startDate: startDate,
        endDate: endDate,
        page: nextPage,
        pageSize: 50,
      );

      final data = (result['data'] as List<dynamic>? ?? [])
          .map((e) => MealLog.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (result['count'] as num?)?.toInt() ?? 0;

      state = state.copyWith(
        meals: [...state.meals, ...data],
        isLoading: false,
        currentPage: nextPage,
        hasMore: (state.meals.length + data.length) < total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Force refresh.
  Future<void> refresh() async {
    state = const MealHistoryState();
    await loadInitial();
  }
}

final mealHistoryProvider =
    StateNotifierProvider<MealHistoryNotifier, MealHistoryState>((ref) {
  return MealHistoryNotifier(ref);
});
