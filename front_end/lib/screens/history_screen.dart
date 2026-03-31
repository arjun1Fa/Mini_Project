import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../providers/meal_history_provider.dart';
import '../providers/profile_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mealHistoryProvider.notifier).loadInitial();
      ref.read(profileProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(mealHistoryProvider);
    final profileState = ref.watch(profileProvider);
    final goalKcal = profileState.profile?.dailyGoalKcal ?? 2000;

    // Use real data if loaded, fallback to sample
    final hasRealData = historyState.meals.isNotEmpty;
    final chartData = hasRealData ? historyState.weeklyCalories : weeklyData;
    final mealEntries = hasRealData
        ? historyState.meals
            .map((m) => MealEntry.fromMealLog(m))
            .toList()
        : sampleMeals;

    final todayCals = hasRealData
        ? historyState.todayCalories.round()
        : 1847;
    final todayProtein = hasRealData
        ? historyState.todayProtein.round()
        : 68;
    final mealCount = hasRealData
        ? historyState.mealCountThisWeek
        : 7;

    final goalPct = goalKcal > 0
        ? ((todayCals / goalKcal) * 100).round()
        : 0;

    return RefreshIndicator(
      color: AppColors.leaf,
      onRefresh: () => ref.read(mealHistoryProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              label: 'Nutrition History',
              title: 'Your Journey',
              subtitle: 'Track your nutrition across time',
            ),

            // ── Loading indicator ──
            if (historyState.isLoading && historyState.meals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.leaf,
                    strokeWidth: 2,
                  ),
                ),
              )
            else ...[
              // ── Stats grid ──
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(
                    value: _formatNumber(todayCals),
                    label: 'Calories Today',
                    change: goalPct > 100
                        ? '↑ ${goalPct - 100}% over goal'
                        : '${goalPct}% of goal',
                    changePositive: goalPct <= 110,
                    accentColor: AppColors.amber,
                  ),
                  _StatCard(
                    value: '${todayProtein}g',
                    label: 'Protein Today',
                    change: todayProtein >= 60
                        ? '↑ on track'
                        : '↓ ${60 - todayProtein}g below target',
                    changePositive: todayProtein >= 60,
                    accentColor: AppColors.leafLight,
                  ),
                  _StatCard(
                    value: '$mealCount',
                    label: 'Meals This Week',
                    change: mealCount >= 14 ? '↑ on track' : '↑ keep logging',
                    changePositive: true,
                    accentColor: AppColors.sky,
                  ),
                  _StatCard(
                    value: '${goalPct.clamp(0, 100)}%',
                    label: 'Daily Goal',
                    change: goalPct >= 80
                        ? '↑ great progress'
                        : '↓ eat more to meet goal',
                    changePositive: goalPct >= 80,
                    accentColor: AppColors.gold,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Bar chart ──
              NvCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Calorie Intake',
                              style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 18, color: AppColors.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last 7 days · Goal: ${_formatNumber(goalKcal)} kcal',
                              style: GoogleFonts.dmMono(
                                  fontSize: 11, color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                        Row(children: [
                          _LegendDot(
                              color: AppColors.leafLight, label: 'Past'),
                          const SizedBox(width: 12),
                          _LegendDot(color: AppColors.leaf, label: 'Today'),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (goalKcal * 1.25).toDouble(),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => AppColors.ink,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${chartData[groupIndex].calories} kcal',
                                  GoogleFonts.dmMono(
                                      color: Colors.white, fontSize: 11),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= chartData.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      chartData[idx].day,
                                      style: GoogleFonts.dmMono(
                                        fontSize: 10,
                                        color: AppColors.inkFaint,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: AppColors.border,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups:
                              chartData.asMap().entries.map((e) {
                            final idx = e.key;
                            final d = e.value;
                            return BarChartGroupData(
                              x: idx,
                              barRods: [
                                BarChartRodData(
                                  toY: d.calories.toDouble(),
                                  color: d.isToday
                                      ? AppColors.leaf
                                      : AppColors.leafLight,
                                  width: 28,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                  backDrawRodData:
                                      BackgroundBarChartRodData(
                                    show: true,
                                    toY: (goalKcal * 1.25).toDouble(),
                                    color: AppColors.creamDark,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Macro breakdown ──
              if (hasRealData)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.3,
                  children: [
                    MacroBar(macro: historyState.proteinGoal(83)),
                    MacroBar(macro: historyState.carbsGoal(250)),
                    MacroBar(macro: historyState.fatGoal(65)),
                    MacroBar(macro: historyState.fiberGoal(30)),
                  ],
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.3,
                  children:
                      macroGoals.map((m) => MacroBar(macro: m)).toList(),
                ),

              const SizedBox(height: 28),

              // ── All meals ──
              Text(
                'All Meals',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20, color: AppColors.ink),
              ),
              const SizedBox(height: 14),

              if (historyState.error != null && historyState.meals.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('📡',
                            style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          'Could not load meals',
                          style: GoogleFonts.dmSans(
                              color: AppColors.inkMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref
                              .read(mealHistoryProvider.notifier)
                              .refresh(),
                          child: Text('Retry',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.leaf,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...mealEntries.map((meal) => MealRow(meal: meal)),

              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k'
          .replaceAll('k', ',${(n % 1000).toString().padLeft(3, '0')}')
          .replaceFirst(RegExp(r',\d{3}$'), ',${n % 1000}');
    }
    // Simple comma formatting
    final str = n.toString();
    if (str.length > 3) {
      return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return str;
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String change;
  final bool changePositive;
  final Color accentColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.change,
    required this.changePositive,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 26, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  change,
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: changePositive ? AppColors.leaf : AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label,
          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.inkMuted)),
    ]);
  }
}
