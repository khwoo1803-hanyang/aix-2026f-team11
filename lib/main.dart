import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/app_config.dart';
import 'services/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isSupabaseConfigured) {
    await initializeSupabase();
  }

  runApp(
    const ProviderScope(
      child: TravelPlannerApp(
        isSupabaseConfigured: AppConfig.isSupabaseConfigured,
      ),
    ),
  );
}
