import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

Future<void> initializeSupabase() {
  return Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
