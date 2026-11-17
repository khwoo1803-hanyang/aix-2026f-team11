import 'package:flutter/material.dart';

class TravelPlannerApp extends StatelessWidget {
  const TravelPlannerApp({super.key, required this.isSupabaseConfigured});

  final bool isSupabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '여행 계획',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('여행 계획')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              isSupabaseConfigured
                  ? 'Supabase 설정이 적용되었습니다.'
                  : 'env.json에 Supabase 설정을 입력해 주세요.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
