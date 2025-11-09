class SupabaseOptions {
  static const String url = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_URL',
    defaultValue: String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
  );

  static const String anonKey = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );

  static void ensureConfigured() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw ArgumentError(
        'Supabase credentials are missing. Pass NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_URL/NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_ANON_KEY (or SUPABASE_URL/SUPABASE_ANON_KEY) via --dart-define.',
      );
    }
  }
}
