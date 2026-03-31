import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Hive-based offline storage for meals that couldn't be saved online.
class OfflineService {
  static const _boxName = 'pending_meals';

  /// Initialize Hive (call once at app startup).
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_boxName);
  }

  Box<Map> get _box => Hive.box<Map>(_boxName);

  /// Save a meal locally for later sync.
  Future<void> saveMealLocally(AnalyzeResult result, double multiplier) async {
    final adjusted = result.withMultiplier(multiplier);
    final data = {
      'items': adjusted.items.map((e) => e.toJson()).toList(),
      'total': adjusted.total.toJson(),
      'image_path': adjusted.imagePath ?? '',
      'logged_at': DateTime.now().toIso8601String(),
      'saved_at': DateTime.now().toIso8601String(),
    };
    await _box.add(data);
  }

  /// Get all pending (unsynced) meals.
  List<Map<dynamic, dynamic>> getPendingMeals() {
    return _box.values.toList();
  }

  /// Number of pending meals.
  int get pendingCount => _box.length;

  /// Attempt to sync all pending meals to the backend.
  /// Returns the number successfully synced.
  Future<int> syncPendingMeals(ApiService apiService) async {
    int synced = 0;
    final keys = _box.keys.toList();

    for (final key in keys) {
      final meal = _box.get(key);
      if (meal == null) continue;

      try {
        final items = (meal['items'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final total = Map<String, dynamic>.from(meal['total'] as Map);
        final loggedAt = DateTime.tryParse(meal['logged_at'] as String? ?? '');

        await apiService.saveMeal(
          items: items,
          total: total,
          loggedAt: loggedAt,
        );
        await _box.delete(key);
        synced++;
      } catch (_) {
        // Still offline or server error — leave for next sync
      }
    }
    return synced;
  }

  /// Clear all pending meals.
  Future<void> clearAll() async {
    await _box.clear();
  }
}
