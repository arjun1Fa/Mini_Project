import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/models.dart';

/// Dio-based HTTP client for the NutriVision backend.
/// Automatically attaches the Supabase JWT to every request.
class ApiService {
  late final Dio _dio;

  /// Optional callback invoked on 401 to redirect to login.
  final void Function()? onUnauthorized;

  ApiService({this.onUnauthorized}) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ));

    // ── JWT interceptor removed ──────────────────────────────
    // Authentication is bypassed.
  }

  // ── POST /api/analyze ──────────────────────────────────
  Future<AnalyzeResult> analyzeImage(
    File imageFile, {
    String plateType = 'standard',
    List<Map<String, dynamic>> foodPredictions = const [],
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'meal_image.jpg',
      ),
      'plate_type': plateType,
      'food_predictions': foodPredictions.toString(),
    });

    final response = await _dio.post('/api/analyze', data: formData);
    return AnalyzeResult.fromJson(
      response.data as Map<String, dynamic>,
      imagePath: imageFile.path,
    );
  }

  // ── POST /api/meals/save ───────────────────────────────
  Future<Map<String, dynamic>> saveMeal({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> total,
    String imageUrl = '',
    DateTime? loggedAt,
  }) async {
    final response = await _dio.post('/api/meals/save', data: {
      'items': items,
      'total': total,
      'image_url': imageUrl,
      'logged_at': (loggedAt ?? DateTime.now()).toIso8601String(),
    });
    return response.data as Map<String, dynamic>;
  }

  // ── GET /api/meals/history ─────────────────────────────
  Future<Map<String, dynamic>> getMealHistory({
    String? startDate,
    String? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get('/api/meals/history', queryParameters: {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      'page': page,
      'page_size': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  // ── GET /api/meals/<id> ────────────────────────────────
  Future<MealLog> getMealDetail(String mealId) async {
    final response = await _dio.get('/api/meals/$mealId');
    return MealLog.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /api/profile ───────────────────────────────────
  Future<UserProfile> getProfile() async {
    final response = await _dio.get('/api/profile');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  // ── PUT /api/profile ───────────────────────────────────
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> updates) async {
    final response = await _dio.put('/api/profile', data: updates);
    return response.data as Map<String, dynamic>;
  }

  // ── GET /api/food/search ───────────────────────────────
  Future<List<FoodSearchResult>> searchFood(String query) async {
    final response = await _dio.get('/api/food/search', queryParameters: {
      'q': query,
    });
    final data = response.data as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>? ?? [])
        .map((e) => FoodSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
    return results;
  }
}
