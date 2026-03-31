import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';

/// Global navigator key for 401 redirect.
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

/// Singleton API service provider.
final apiServiceProvider = Provider<ApiService>((ref) {
  final navKey = ref.read(navigatorKeyProvider);
  return ApiService(
    onUnauthorized: () {
      // On 401, clear session and navigate to login
      navKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    },
  );
});

/// Singleton offline service provider.
final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
});
