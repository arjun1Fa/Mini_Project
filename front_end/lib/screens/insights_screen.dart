import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                _ScoreRing(score: 70),
                const SizedBox(height: 24),
                Text(
                  'Good Progress 🌿',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "You're making solid healthy choices.\nA few tweaks will push you to excellent.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white60,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                _ScoreBreakdown(),
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
          ...insights.map((i) => _InsightCard(item: i)),
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
  final _items = const [
    ('Protein', 0.82, AppColors.leafLight),
    ('Carbs', 0.88, AppColors.amber),
    ('Fats', 0.89, AppColors.sky),
    ('Variety', 0.75, AppColors.gold),
  ];

  const _ScoreBreakdown();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _items.map((item) {
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
            Padding(
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
          ],
        ),
      ),
    );
  }
}
