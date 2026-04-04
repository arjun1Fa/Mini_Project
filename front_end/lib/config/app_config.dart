/// Centralized configuration for NutriVision.
class AppConfig {
  // ── Backend API ────────────────────────────────────────
  /// For local testing on Android Emulator, use 10.0.2.2 instead of localhost.
  /// If using iOS simulator or Web, use http://127.0.0.1:8080
  /// If using a real physical phone, use your Wi-Fi IP (e.g. http://192.168.1.5:8080)
  static const apiBaseUrl = 'http://192.168.29.10:8080';

  // ── Supabase Configuration ─────────────────────────────
  // IMPORTANT: Replace with actual Supabase Anon Key.
  static const supabaseUrl = 'https://msyhqpazjzoiawyrymgz.supabase.co';
  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // ── SharedPreferences Keys ─────────────────────────────
  static const keyJwt = 'nv_jwt_token';
  static const keyUserId = 'nv_user_id';
  static const keyPlateType = 'nv_plate_type';
  static const keyDailyGoal = 'nv_daily_goal_kcal';

  // ── Image Quality ──────────────────────────────────────
  static const double sharpnessThreshold = 100.0;
  static const int sharpnessCropSize = 50;

  // ── Portion Multipliers ────────────────────────────────
  static const portionOptions = {
    'Small': 0.75,
    'Medium': 1.0,
    'Large': 1.25,
    'XL': 1.5,
  };
}
