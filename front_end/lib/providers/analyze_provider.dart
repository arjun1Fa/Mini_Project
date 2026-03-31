import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

/// Holds the current analysis result (null until an analysis completes).
final analyzeResultProvider = StateProvider<AnalyzeResult?>((ref) => null);

/// Current portion multiplier (Small 0.75, Medium 1.0, Large 1.25, XL 1.5).
final portionMultiplierProvider = StateProvider<double>((ref) => 1.0);

/// Computed provider: returns the analysis result with nutrition scaled
/// by the current portion multiplier.
final adjustedResultProvider = Provider<AnalyzeResult?>((ref) {
  final result = ref.watch(analyzeResultProvider);
  final multiplier = ref.watch(portionMultiplierProvider);
  if (result == null) return null;
  if (multiplier == 1.0) return result;
  return result.withMultiplier(multiplier);
});
