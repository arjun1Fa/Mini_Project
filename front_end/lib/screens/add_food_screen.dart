import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'image_preview_screen.dart';

class AddFoodScreen extends StatelessWidget {
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
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(
              imagePath: pickedFile.path,
              onAnalyzeCompete: () {
                Navigator.pop(context); // Pop preview
                onGoToManual(); // Proceed to manual entry
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Error picking image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            childAspectRatio: 0.85,
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
          ...sampleMeals.take(3).map((meal) => MealRow(meal: meal)),

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
