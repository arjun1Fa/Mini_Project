import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_quality_service.dart';
import '../providers/meal_history_provider.dart';
import 'processing_screen.dart';

class AddFoodScreen extends ConsumerWidget {
  final VoidCallback onGoToHistory;
  final VoidCallback onGoToManual;

  const AddFoodScreen({
    super.key,
    required this.onGoToHistory,
    required this.onGoToManual,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile != null && context.mounted) {
        // ── Image quality gate ──
        final bytes = await File(pickedFile.path).readAsBytes();
        final (isSharp, score) = ImageQualityService.checkSharpness(bytes);

        if (!isSharp && context.mounted) {
          final shouldContinue = await _showBlurWarning(context, score);
          if (!shouldContinue) return; // User chose to retake
        }

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProcessingScreen(imagePath: pickedFile.path),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Error picking image: $e');
      }
    }
  }

  /// Show blur warning. Returns true if user wants to continue anyway.
  Future<bool> _showBlurWarning(BuildContext context, double score) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text('Blurry Image',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20, color: AppColors.ink)),
          ],
        ),
        content: Text(
          'This image may be blurry (sharpness: ${score.toStringAsFixed(0)}). '
          'Retake for better results?',
          style: GoogleFonts.dmSans(color: AppColors.inkSoft, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Use Anyway',
                style: GoogleFonts.dmSans(
                    color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.leaf,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Retake', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            label: 'Log a Meal',
            title: 'What did you eat?',
            subtitle: "Choose how you'd like to record your meal",
          ),

          // ── Input option cards ──
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
            children: [
              InputOptionCard(
                emoji: '📸',
                title: 'Take Photo',
                description:
                    'Snap your meal and let AI identify food and estimate portions automatically.',
                accentColor: AppColors.leafLight,
                bgColor: AppColors.leafPale,
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              InputOptionCard(
                emoji: '🖼️',
                title: 'Upload Photo',
                description:
                    'Choose an existing photo from your gallery to analyze.',
                accentColor: AppColors.amber,
                bgColor: AppColors.amberPale,
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
              InputOptionCard(
                emoji: '✍️',
                title: 'Manual Entry',
                description:
                    'Type in food details and nutritional information manually.',
                accentColor: AppColors.gold,
                bgColor: AppColors.goldPale,
                onTap: onGoToManual,
              ),
              InputOptionCard(
                emoji: '🔍',
                title: 'Search Food',
                description:
                    'Search our database of over 1 million food items.',
                accentColor: AppColors.sky,
                bgColor: AppColors.skyPale,
                onTap: () => _showSnack(context, '🔍 Food search coming soon'),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Recent meals header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Meals',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20, color: AppColors.ink),
              ),
              GestureDetector(
                onTap: onGoToHistory,
                child: Text(
                  'View All →',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.leaf,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Meals list ──
          Builder(builder: (context) {
            final historyState = ref.watch(mealHistoryProvider);
            final recentMeals = historyState.meals
                .take(3)
                .map((m) => MealEntry.fromMealLog(m))
                .toList();

            if (recentMeals.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'No recent meals',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your logged meals will appear here',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: recentMeals.map((meal) => MealRow(meal: meal)).toList(),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
