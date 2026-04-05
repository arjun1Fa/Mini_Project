import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../providers/meal_history_provider.dart';
import '../providers/profile_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(mealHistoryProvider);
    final profileState = ref.watch(profileProvider);
    final goalKcal = profileState.profile?.dailyGoalKcal ?? 2000;
    
    // Calculate a basic score based on macros
    final hasRealData = historyState.meals.isNotEmpty;
    
    int score = 70;
    String scoreTitle = 'Good Progress 🌿';
    String scoreSubtitle = "You're making solid healthy choices.\nA few tweaks will push you to excellent.";
    
    List<(String, double, Color)> breakdownItems = [
      ('Protein', 0.82, AppColors.leafLight),
      ('Carbs', 0.88, AppColors.amber),
      ('Fats', 0.89, AppColors.sky),
      ('Fiber', 0.75, AppColors.gold),
    ];

    List<InsightItem> derivedInsights = [
      const InsightItem(
        emoji: '📸',
        title: 'Start Tracking',
        body: 'Log your first meal to get personalized nutrition insights and recommendations.',
        accentColor: 0xFF52B788,
        bgColor: 0xFFD8F3DC,
      ),
      const InsightItem(
        emoji: '💧',
        title: 'Hydration Reminder',
        body: "Don't forget to stay hydrated throughout the day. Aim for 8 glasses of water to support digestion.",
        accentColor: 0xFFC9A84C,
        bgColor: 0xFFFDF3D9,
      ),
    ];

    if (hasRealData && goalKcal > 0) {
      final todayCals = historyState.todayCalories;
      final todayProtein = historyState.todayProtein;
      final todayCarbs = historyState.carbsGoal(250).current;
      final todayFat = historyState.fatGoal(65).current;
      final todayFiber = historyState.fiberGoal(30).current;

      double calRatio = (todayCals / goalKcal).clamp(0.0, 1.0);
      double proRatio = (todayProtein / historyState.proteinGoal(83).goal).clamp(0.0, 1.0);
      double carbRatio = (todayCarbs / historyState.carbsGoal(250).goal).clamp(0.0, 1.0);
      double fatRatio = (todayFat / historyState.fatGoal(65).goal).clamp(0.0, 1.0);
      double fiberRatio = (todayFiber / historyState.fiberGoal(30).goal).clamp(0.0, 1.0);

      breakdownItems = [
        ('Protein', proRatio, AppColors.leafLight),
        ('Carbs', carbRatio, AppColors.amber),
        ('Fats', fatRatio, AppColors.sky),
        ('Fiber', fiberRatio, AppColors.gold),
      ];

      double avgMacro = (proRatio + carbRatio + fatRatio + fiberRatio) / 4.0;
      double calScore = calRatio > 0.8 ? 1.0 : calRatio;
      
      score = ((avgMacro * 0.7 + calScore * 0.3) * 100).toInt();
      
      if (score > 85) {
        scoreTitle = 'Excellent 🌟';
        scoreSubtitle = "You're crushing your nutrition goals!";
      } else if (score < 50) {
        scoreTitle = 'Needs Work ⚠️';
        scoreSubtitle = "Try actively tracking your macros and choosing whole foods.";
      }

      // Generate some dynamic insights
      derivedInsights = [];
      if (proRatio < 0.8) {
        derivedInsights.add(const InsightItem(
          emoji: '💪',
          title: 'Increase Protein Intake',
          body: "You're below your daily protein goal. Try adding lean meats, eggs, or legumes to your next meal.",
          accentColor: 0xFF52B788,
          bgColor: 0xFFD8F3DC,
        ));
      } else {
        derivedInsights.add(const InsightItem(
          emoji: '💪',
          title: 'Protein Goal Met',
          body: "Great job hitting your protein targets! This supports muscle recovery.",
          accentColor: 0xFF52B788,
          bgColor: 0xFFD8F3DC,
        ));
      }

      if (fiberRatio < 0.6) {
        derivedInsights.add(const InsightItem(
          emoji: '🌾',
          title: 'Add More Fiber',
          body: "You're low on fiber. Include more whole grains, legumes, and fruits.",
          accentColor: 0xFF2D6A4F,
          bgColor: 0xFFD8F3DC,
        ));
      }

      // Keep energy balance if calories are somewhat close
      if (calRatio > 0.6 && calRatio < 1.1) {
        derivedInsights.add(const InsightItem(
          emoji: '⚡',
          title: 'Energy Balance',
          body: 'Your calorie intake is well-balanced. Maintain this for steady, sustainable progress.',
          accentColor: 0xFFE76F51,
          bgColor: 0xFFFDE8DF,
        ));
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            label: 'Analysis',
            title: 'Health Insights',
            subtitle: 'Your personal nutrition score and recommendations',
          ),

          // ── Score card ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  'NUTRITION SCORE',
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 24),
                _ScoreRing(score: score),
                const SizedBox(height: 24),
                Text(
                  scoreTitle,
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  scoreSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white60,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                _ScoreBreakdown(items: breakdownItems),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Insight cards ──
          Text(
            'Recommendations',
            style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppColors.ink),
          ),
          const SizedBox(height: 14),
          ...derivedInsights.map((i) => _InsightCard(item: i)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Score ring painter ─────────────────────────────────
class _ScoreRing extends StatefulWidget {
  final int score;
  const _ScoreRing({required this.score});

  @override
  State<_ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<_ScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween(begin: 0.0, end: widget.score / 100.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          return CustomPaint(
            painter: _RingPainter(progress: _anim.value),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(widget.score * _anim.value).toInt()}',
                    style: GoogleFonts.dmSerifDisplay(
                        fontSize: 44, color: Colors.white, height: 1),
                  ),
                  Text(
                    '/100',
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = AppColors.leafLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _ScoreBreakdown extends StatelessWidget {
  final List<(String, double, Color)> items;

  const _ScoreBreakdown({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final (label, pct, color) = item;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            SizedBox(
              width: 64,
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: Colors.white60),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 28,
              child: Text(
                '${(pct * 100).toInt()}',
                textAlign: TextAlign.right,
                style: GoogleFonts.dmMono(
                    fontSize: 11, color: Colors.white54),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final InsightItem item;
  const _InsightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = Color(item.accentColor);
    final bg = Color(item.bgColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14)),
              ),
            ),
            Expanded(
              child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(10)),
                    child: Center(
                        child: Text(item.emoji,
                            style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.body,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
