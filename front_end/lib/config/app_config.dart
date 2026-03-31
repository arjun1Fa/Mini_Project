/// Centralized configuration for NutriVision.
class AppConfig {
  // ── Supabase ───────────────────────────────────────────
  static const supabaseUrl = 'https://msyhqpazjzoiawyrymgz.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zeWhxcGF6anpvaWF3eXJ5bWd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDg2NTUsImV4cCI6MjA5MDEyNDY1NX0.'
      'YOUR_ANON_KEY_SIGNATURE'; // TODO: replace with your anon key from Supabase Dashboard → Settings → API

  // ── Backend API ────────────────────────────────────────
  /// Replace with your deployed Cloud Run URL.
  static const apiBaseUrl = 'https://YOUR_CLOUD_RUN_URL';

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
