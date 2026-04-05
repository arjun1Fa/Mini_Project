/// Centralized configuration for NutriVision.
class AppConfig {
  // ── Backend API ────────────────────────────────────────
  /// ⚠️ UPDATE THIS to match where your Flask backend is running:
  /// - Android Emulator → 'http://10.0.2.2:8080'
  /// - Physical phone (same WiFi) → 'http://<your-PC-IP>:8080'
  /// - iOS Simulator or Web → 'http://127.0.0.1:8080'
  /// Find your IP: run 'ipconfig' in command prompt, look for "IPv4 Address"
  static const apiBaseUrl = 'http://172.28.106.47:8080';

  // ── Supabase Configuration ─────────────────────────────
  static const supabaseUrl = 'https://msyhqpazjzoiawyrymgz.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zeWhxcGF6anpvaWF3eXJ5bWd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDg2NTUsImV4cCI6MjA5MDEyNDY1NX0.YOwElemIfNolwDLi551UAKkBM_ZcI6MlirsY7XKKiCk';

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
