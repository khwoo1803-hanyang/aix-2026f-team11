import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/supabase_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(supabase);
});

final sessionProvider = StreamProvider<Session?>((ref) {
  return ref.watch(authServiceProvider).sessionChanges();
});
