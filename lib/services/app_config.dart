/// 빌드할 때 `--dart-define-from-file=env.json`으로 전달되는 설정값.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const isSupabaseConfigured =
      supabaseUrl != '' && supabasePublishableKey != '';
}
