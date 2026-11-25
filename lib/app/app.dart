import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/room_list_screen.dart';
import 'travel_theme.dart';

class TravelPlannerApp extends StatelessWidget {
  const TravelPlannerApp({super.key, required this.isSupabaseConfigured});

  final bool isSupabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '여행 계획',
      theme: travelTheme(),
      home: isSupabaseConfigured
          ? const AuthGate()
          : const SetupRequiredScreen(),
    );
  }
}

/// 로그인 상태에 따라 로그인 화면과 여행방 목록을 바꿔 보여준다.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return session.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LoginScreen(),
      data: (value) =>
          value == null ? const LoginScreen() : const RoomListScreen(),
    );
  }
}

class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('여행 계획')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'env.json에 Supabase 설정을 입력해 주세요.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
