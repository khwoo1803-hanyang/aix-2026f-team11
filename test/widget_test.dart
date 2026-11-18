import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:travel_planner/app/app.dart';
import 'package:travel_planner/app/screens/auth/login_screen.dart';
import 'package:travel_planner/providers/auth_provider.dart';
import 'package:travel_planner/services/auth_service.dart';

class _FakeAuthService implements AuthService {
  int signInCalls = 0;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    throw const AuthException('Invalid login credentials');
  }

  @override
  Stream<Session?> sessionChanges() => Stream.value(null);

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async =>
      SignUpResult.needsEmailConfirmation;

  @override
  Future<void> signOut() async {}
}

Widget _loginWith(_FakeAuthService auth) {
  return ProviderScope(
    overrides: [authServiceProvider.overrideWithValue(auth)],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  testWidgets('Supabase 설정이 없으면 안내 문구를 표시한다', (tester) async {
    await tester.pumpWidget(
      const TravelPlannerApp(isSupabaseConfigured: false),
    );

    expect(find.text('env.json에 Supabase 설정을 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('로그인하지 않았으면 로그인 화면을 보여준다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_FakeAuthService()),
        ],
        child: const TravelPlannerApp(isSupabaseConfigured: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('입력이 잘못되면 서버에 요청하지 않는다', (tester) async {
    final auth = _FakeAuthService();
    await tester.pumpWidget(_loginWith(auth));

    await tester.enterText(find.byKey(const Key('email')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('password')), '123');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();

    expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호는 6자 이상이어야 합니다.'), findsOneWidget);
    expect(auth.signInCalls, 0);
  });

  testWidgets('로그인 실패 이유를 한국어로 보여준다', (tester) async {
    final auth = _FakeAuthService();
    await tester.pumpWidget(_loginWith(auth));

    await tester.enterText(find.byKey(const Key('email')), 'a@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 1);
    expect(find.text('이메일 또는 비밀번호가 맞지 않습니다.'), findsOneWidget);
  });

  testWidgets('회원가입 후 메일 확인이 필요하면 안내한다', (tester) async {
    await tester.pumpWidget(_loginWith(_FakeAuthService()));

    await tester.tap(find.text('처음이에요, 회원가입'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('nickname')), '현우');
    await tester.enterText(find.byKey(const Key('email')), 'a@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, '가입하기'));
    await tester.pumpAndSettle();

    expect(
      find.text('가입 확인 메일을 보냈습니다. 링크를 누른 뒤 로그인해 주세요.'),
      findsOneWidget,
    );
  });
}
