import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/offline_portions.dart';
import '../providers/api_provider.dart';
import '../providers/analyze_provider.dart';
import '../providers/profile_provider.dart';
import 'results_screen.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const ProcessingScreen({super.key, required this.imagePath});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _stepCtrl;
  int _currentStep = 0;
  bool _isDone = false;
  String? _error;

  final _steps = [
    ('🔍', 'Detecting food items…'),
    ('⚖️', 'Estimating portions…'),
    ('🧮', 'Calculating nutrition…'),
  ];

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _startAnalysis();
  }

  @override
  void dispose() {
    _stepCtrl.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    // Animate steps while the API call runs in parallel
    final analysisFuture = _callAnalyzeApi();

    // Step 1
    setState(() => _currentStep = 0);
    _stepCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1200));

    // Step 2
    if (mounted) setState(() => _currentStep = 1);
    _stepCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1200));

    // Step 3
    if (mounted) setState(() => _currentStep = 2);
    _stepCtrl.forward(from: 0);

    // Wait for the API call to finish
    await analysisFuture;
  }

  Future<void> _callAnalyzeApi() async {
    try {
      final api = ref.read(apiServiceProvider);
      final profileState = ref.read(profileProvider);
      final plateType = profileState.profile?.plateType ?? 'standard';

      final result = await api.analyzeImage(
        File(widget.imagePath),
        plateType: plateType,
      );

      // Store the result with the image path
      final resultWithImage = AnalyzeResult(
        items: result.items,
        total: result.total,
        processingTimeMs: result.processingTimeMs,
        imagePath: widget.imagePath,
      );

      ref.read(analyzeResultProvider.notifier).state = resultWithImage;
      ref.read(portionMultiplierProvider.notifier).state = 1.0;

      if (mounted) {
        setState(() => _isDone = true);
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToResults();
      }
    } catch (e) {
      // Offline or server error — use fallback data
      if (mounted) {
        _handleOfflineMode();
      }
    }
  }

  void _handleOfflineMode() {
    final fallbackItems = OfflinePortions.asAnalyzeItems()
        .map((e) => AnalyzedFoodItem.fromJson(e))
        .toList();

    final totalNutrition = fallbackItems.fold<NutritionInfo>(
      const NutritionInfo(),
      (sum, item) => sum + item.nutrition,
    );

    final offlineResult = AnalyzeResult(
      items: fallbackItems,
      total: totalNutrition,
      isOffline: true,
      imagePath: widget.imagePath,
    );

    ref.read(analyzeResultProvider.notifier).state = offlineResult;
    ref.read(portionMultiplierProvider.notifier).state = 1.0;

    setState(() {
      _isDone = true;
      _error = 'offline';
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '📡 Offline mode — using standard serving sizes',
        style: GoogleFonts.dmSans(),
      ),
      backgroundColor: AppColors.gold,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _navigateToResults();
    });
  }

  void _navigateToResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          // ── Background image (dimmed) ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ── Content ──
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.leafLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('🌿', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Analyzing Your Meal',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 26,
                      color: AppColors.cream,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Steps ──
                  ...List.generate(_steps.length, (i) {
                    final (emoji, label) = _steps[i];
                    final isActive = _currentStep == i;
                    final isCompleted = _currentStep > i || _isDone;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          // Status icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.leaf
                                  : isActive
                                      ? AppColors.leafLight.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : Text(emoji,
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: isActive
                                              ? null
                                              : Colors.white24)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight:
                                    isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive || isCompleted
                                    ? AppColors.cream
                                    : Colors.white30,
                              ),
                            ),
                          ),
                          if (isActive && !_isDone)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.leafLight.withOpacity(0.6),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  if (_isDone) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error == 'offline'
                          ? '📡 Using offline estimates'
                          : '✅ Analysis complete!',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: AppColors.leafLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
