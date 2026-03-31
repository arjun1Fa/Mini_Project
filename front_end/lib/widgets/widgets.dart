import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ── Section Header ─────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String label;
  final String title;
  final String? subtitle;

  const SectionHeader({
    super.key,
    required this.label,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmMono(
            fontSize: 11,
            letterSpacing: 1.4,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: AppColors.ink),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.inkMuted),
          ),
        ],
      ]),
    );
  }
}

// ── Meal Row ───────────────────────────────────────────
class MealRow extends StatelessWidget {
  final MealEntry meal;

  const MealRow({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(meal.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      _macroPill('●', AppColors.amber, '${meal.calories} kcal'),
                      const SizedBox(width: 10),
                      _macroPill('●', AppColors.leafLight, '${meal.protein.toInt()}g protein'),
                      const SizedBox(width: 10),
                      _macroPill('●', AppColors.sky, '${meal.fat.toInt()}g fat'),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                meal.timeAgo,
                style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.inkFaint),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _macroPill(String dot, Color color, String text) {
    return Row(children: [
      Text(dot, style: TextStyle(fontSize: 8, color: color)),
      const SizedBox(width: 3),
      Text(
        text,
        style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.inkMuted),
      ),
    ]);
  }
}

// ── NvCard ─────────────────────────────────────────────
class NvCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;

  const NvCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    );
  }
}

// ── Macro Progress Bar ─────────────────────────────────
class MacroBar extends StatelessWidget {
  final MacroGoal macro;

  const MacroBar({super.key, required this.macro});

  @override
  Widget build(BuildContext context) {
    final color = Color(macro.colorValue);
    return NvCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              macro.name,
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink),
            ),
            Text(
              macro.label,
              style: GoogleFonts.dmMono(
                  fontSize: 12, color: AppColors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: macro.pct,
            minHeight: 6,
            backgroundColor: AppColors.creamDark,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(macro.pct * 100).toInt()}% of daily goal',
          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.inkMuted),
        ),
      ]),
    );
  }
}

// ── Input Option Card ──────────────────────────────────
class InputOptionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback onTap;

  const InputOptionCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    description,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chip selector ──────────────────────────────────────
class NvChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const NvChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.leaf : AppColors.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.leaf : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
