import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../config/app_config.dart';
import '../providers/analyze_provider.dart';
import '../providers/api_provider.dart';
import '../providers/meal_history_provider.dart';
import '../widgets/widgets.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool _isSaving = false;
  String _selectedPortion = 'Medium';
  Timer? _searchDebounce;
  List<FoodSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(adjustedResultProvider);
    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Text('No analysis results',
              style: GoogleFonts.dmSans(color: AppColors.inkMuted)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Analysis Results',
            style: GoogleFonts.dmSerifDisplay(color: AppColors.ink)),
        backgroundColor: AppColors.cream.withOpacity(0.95),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Offline banner ──
            if (result.isOffline)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.goldPale,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('📡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Offline mode — standard serving sizes applied',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Image with bounding boxes ──
            if (result.imagePath != null)
              NvCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _BoundingBoxImage(
                    imagePath: result.imagePath!,
                    items: result.items,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // ── Portion adjuster ──
            _label('PORTION SIZE'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConfig.portionOptions.entries.map((e) {
                final isSelected = _selectedPortion == e.key;
                return NvChip(
                  label: '${e.key} (${e.value}×)',
                  selected: isSelected,
                  onTap: () {
                    setState(() => _selectedPortion = e.key);
                    ref.read(portionMultiplierProvider.notifier).state = e.value;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Total summary card ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'TOTAL NUTRITION',
                    style: GoogleFonts.dmMono(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${result.total.calories.round()}',
                    style: GoogleFonts.dmSerifDisplay(
                        fontSize: 48, color: Colors.white),
                  ),
                  Text('calories',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: Colors.white60)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _totalMacro(
                          'Protein', '${result.total.proteinG.toStringAsFixed(1)}g',
                          AppColors.leafLight),
                      _totalMacro(
                          'Carbs', '${result.total.carbsG.toStringAsFixed(1)}g',
                          AppColors.amber),
                      _totalMacro(
                          'Fat', '${result.total.fatG.toStringAsFixed(1)}g',
                          AppColors.sky),
                      _totalMacro(
                          'Fiber', '${result.total.fiberG.toStringAsFixed(1)}g',
                          AppColors.gold),
                    ],
                  ),
                  if (result.processingTimeMs > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Processed in ${result.processingTimeMs}ms',
                      style: GoogleFonts.dmMono(
                          fontSize: 11, color: Colors.white30),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Detected food items ──
            Text(
              'Detected Items',
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20, color: AppColors.ink),
            ),
            const SizedBox(height: 14),
            ...result.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return _FoodItemCard(
                item: item,
                index: idx,
                onCorrectName: () => _showFoodSearchModal(context, idx),
              );
            }),
            const SizedBox(height: 24),

            // ── Save button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveMeal(result),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(_isSaving ? 'Saving…' : 'Save Meal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.leaf,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _totalMacro(String label, String value, Color color) {
    return Column(children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(height: 6),
      Text(value,
          style: GoogleFonts.dmSans(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label,
          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white54)),
    ]);
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }

  Future<void> _saveMeal(AnalyzeResult result) async {
    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.saveMeal(
        items: result.items.map((e) => e.toJson()).toList(),
        total: result.total.toJson(),
        imageUrl: result.imagePath ?? '',
      );

      // Refresh meal history so the new meal shows up immediately
      ref.read(mealHistoryProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Meal saved successfully!',
              style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.leaf,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      // Offline save
      try {
        final offline = ref.read(offlineServiceProvider);
        final multiplier = ref.read(portionMultiplierProvider);
        final rawResult = ref.read(analyzeResultProvider);
        if (rawResult != null) {
          await offline.saveMealLocally(rawResult, multiplier);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('💾 Saved offline — will sync when connected',
                style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.gold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ));
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Failed to save. Please try again.',
                style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.amber,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showFoodSearchModal(BuildContext context, int itemIndex) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Correct Food Name',
                    style: GoogleFonts.dmSerifDisplay(
                        fontSize: 20, color: AppColors.ink)),
                const SizedBox(height: 16),
                TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search food…',
                    prefixIcon: Icon(Icons.search, color: AppColors.inkMuted),
                  ),
                  style: GoogleFonts.dmSans(color: AppColors.ink),
                  onChanged: (q) {
                    _searchDebounce?.cancel();
                    _searchDebounce =
                        Timer(const Duration(milliseconds: 400), () async {
                      if (q.length < 2) {
                        setModalState(() {
                          _searchResults = [];
                          _isSearching = false;
                        });
                        return;
                      }
                      setModalState(() => _isSearching = true);
                      try {
                        final api = ref.read(apiServiceProvider);
                        final results = await api.searchFood(q);
                        setModalState(() {
                          _searchResults = results;
                          _isSearching = false;
                        });
                      } catch (_) {
                        setModalState(() => _isSearching = false);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_isSearching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.leaf, strokeWidth: 2),
                    ),
                  ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) {
                      final r = _searchResults[i];
                      final name =
                          r.foodName.replaceAll('_', ' ').split(' ').map((w) {
                        if (w.isEmpty) return w;
                        return w[0].toUpperCase() + w.substring(1);
                      }).join(' ');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(name,
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        subtitle: Text(
                          '${r.caloriesPer100g.round()} kcal/100g · P${r.proteinPer100g.round()} C${r.carbsPer100g.round()} F${r.fatPer100g.round()}',
                          style: GoogleFonts.dmMono(
                              fontSize: 11, color: AppColors.inkMuted),
                        ),
                        onTap: () {
                          // Replace the food name in the result
                          final currentResult =
                              ref.read(analyzeResultProvider);
                          if (currentResult != null &&
                              itemIndex < currentResult.items.length) {
                            currentResult.items[itemIndex].foodName = name;
                            // Force rebuild
                            ref.read(analyzeResultProvider.notifier).state =
                                AnalyzeResult(
                              items: currentResult.items,
                              total: currentResult.total,
                              processingTimeMs: currentResult.processingTimeMs,
                              isOffline: currentResult.isOffline,
                              imagePath: currentResult.imagePath,
                            );
                          }
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

// ── Image with bounding boxes overlay ──────────────────────
class _BoundingBoxImage extends StatelessWidget {
  final String imagePath;
  final List<AnalyzedFoodItem> items;

  const _BoundingBoxImage({required this.imagePath, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      return Stack(
        children: [
          Image.file(
            File(imagePath),
            width: constraints.maxWidth,
            fit: BoxFit.fitWidth,
          ),
          // Draw bounding boxes
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final bb = item.boundingBox;
            if (bb.w == 0 && bb.h == 0) return const SizedBox.shrink();

            final colors = [
              AppColors.leafLight,
              AppColors.amber,
              AppColors.sky,
              AppColors.gold,
              AppColors.leaf,
            ];
            final color = colors[entry.key % colors.length];

            return Positioned(
              left: bb.x.toDouble(),
              top: bb.y.toDouble(),
              child: Container(
                width: bb.w.toDouble(),
                height: bb.h.toDouble(),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: Text(
                      item.foodName,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}

// ── Single food item card ────────────────────────────────────
class _FoodItemCard extends StatelessWidget {
  final AnalyzedFoodItem item;
  final int index;
  final VoidCallback onCorrectName;

  const _FoodItemCard({
    required this.item,
    required this.index,
    required this.onCorrectName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.leafLight,
      AppColors.amber,
      AppColors.sky,
      AppColors.gold,
      AppColors.leaf,
    ];
    final accent = colors[index % colors.length];

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.foodName,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (item.confidence > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(item.confidence * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.dmMono(
                                  fontSize: 11, color: accent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.weightG.toStringAsFixed(0)}g serving',
                      style: GoogleFonts.dmMono(
                          fontSize: 12, color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 12),

                    // Macro grid
                    Row(
                      children: [
                        _macroPill('Cal', '${item.nutrition.calories.round()}',
                            AppColors.amber),
                        const SizedBox(width: 8),
                        _macroPill('P',
                            '${item.nutrition.proteinG.toStringAsFixed(1)}g',
                            AppColors.leafLight),
                        const SizedBox(width: 8),
                        _macroPill('C',
                            '${item.nutrition.carbsG.toStringAsFixed(1)}g',
                            AppColors.sky),
                        const SizedBox(width: 8),
                        _macroPill('F',
                            '${item.nutrition.fatG.toStringAsFixed(1)}g',
                            AppColors.gold),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Correct button
                    GestureDetector(
                      onTap: onCorrectName,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 14, color: AppColors.leaf),
                          const SizedBox(width: 4),
                          Text(
                            'Correct food name',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.leaf,
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

  Widget _macroPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.dmMono(fontSize: 10, color: color)),
          const SizedBox(width: 3),
          Text(value,
              style: GoogleFonts.dmMono(
                  fontSize: 11,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
