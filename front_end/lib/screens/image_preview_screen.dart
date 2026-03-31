import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;
  final VoidCallback onAnalyzeCompete;

  const ImagePreviewScreen({
    super.key,
    required this.imagePath,
    required this.onAnalyzeCompete,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  bool _isAnalyzing = false;

  void _analyzeImage() async {
    setState(() => _isAnalyzing = true);
    // Mock network request or AI processing delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      widget.onAnalyzeCompete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Image Preview', style: GoogleFonts.dmSerifDisplay(color: AppColors.ink)),
        backgroundColor: AppColors.cream.withOpacity(0.95),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeImage,
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Analyze Food'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leaf,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Retake Photo'),
                ),
              ],
            ),
          ),
          if (_isAnalyzing)
            Container(
              color: AppColors.cream.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.leaf),
                    const SizedBox(height: 16),
                    Text('Analyzing...', style: GoogleFonts.dmSans(fontSize: 16, color: AppColors.ink)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
