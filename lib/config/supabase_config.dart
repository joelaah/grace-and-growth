/// Centralized Supabase environment configuration.
///
/// This configuration supports both build-time and runtime environment injection:
/// 1. `--dart-define-from-file=.env` (recommended for local development and CI)
/// 2. `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///
/// If environment variables are omitted or empty, the app runs strictly in
/// offline mode using local bundled seed assets (`seed_verses.json`) and
/// local device storage without hardcoded credentials or dead endpoints.
class SupabaseConfig {
  SupabaseConfig._();

  /// The Supabase project URL injected via environment.
  /// Overridden via `--dart-define=SUPABASE_URL=...` or `--dart-define-from-file=.env`.
  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// The Supabase anon / publishable key injected via environment.
  /// Overridden via `--dart-define=SUPABASE_ANON_KEY=...`,
  /// `--dart-define=SUPABASE_PUBLISHABLE_KEY=...` or `--dart-define-from-file=.env`.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  /// Alias for [publishableKey] for backwards-compatibility.
  static String get anonKey => publishableKey;

  /// Validates whether a URL and Key pair represent a well-formed Supabase endpoint.
  static bool isValidConfig(String rawUrl, String rawKey) {
    final cleanUrl = rawUrl.trim();
    final cleanKey = rawKey.trim();

    if (cleanUrl.isEmpty || cleanKey.isEmpty) {
      return false;
    }

    // Reject template placeholders
    if (cleanUrl.contains('your-project-id') ||
        cleanKey.contains('your-supabase-')) {
      return false;
    }

    final uri = Uri.tryParse(cleanUrl);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !uri.hasAuthority ||
        uri.host.isEmpty) {
      return false;
    }

    return true;
  }

  /// Checks whether both URL and Publishable Key are configured and properly structured.
  static bool get isConfigured => isValidConfig(url, publishableKey);
}
