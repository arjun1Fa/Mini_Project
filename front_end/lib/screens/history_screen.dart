import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            label: 'Nutrition History',
            title: 'Your Journey',
            subtitle: 'Track your nutrition across time',
          ),

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
                value: '1,847',
                label: 'Calories Today',
                change: '↑ 12% vs goal',
                changePositive: true,
                accentColor: AppColors.amber,
              ),
              _StatCard(
                value: '68g',
                label: 'Protein Today',
                change: '↓ 15g below goal',
                changePositive: false,
                accentColor: AppColors.leafLight,
              ),
              _StatCard(
                value: '7',
                label: 'Meals This Week',
                change: '↑ on track',
                changePositive: true,
                accentColor: AppColors.sky,
              ),
              _StatCard(
                value: '85%',
                label: 'Weekly Goal',
                change: '↑ great progress',
                changePositive: true,
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
                          'Last 7 days · Goal: 2,000 kcal',
                          style: GoogleFonts.dmMono(
                              fontSize: 11, color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                    Row(children: [
                      _LegendDot(color: AppColors.leafLight, label: 'Past'),
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
                      maxY: 2500,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.ink,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${weeklyData[groupIndex].calories} kcal',
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
                              if (idx < 0 || idx >= weeklyData.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  weeklyData[idx].day,
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
                      barGroups: weeklyData.asMap().entries.map((e) {
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
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 2500,
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.3,
            children: macroGoals.map((m) => MacroBar(macro: m)).toList(),
          ),

          const SizedBox(height: 28),

          // ── All meals ──
          Text(
            'All Meals',
            style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppColors.ink),
          ),
          const SizedBox(height: 14),
          ...sampleMeals.map((meal) => MealRow(meal: meal)),
          const SizedBox(height: 24),
        ],
      ),
    );
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
          width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label,
          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.inkMuted)),
    ]);
  }
}
