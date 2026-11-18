import 'package:supabase_flutter/supabase_flutter.dart';

enum SignUpResult { signedIn, needsEmailConfirmation }

class AuthService {
  const AuthService(this._client);

  final SupabaseClient _client;

  Stream<Session?> sessionChanges() async* {
    yield _client.auth.currentSession;
    yield* _client.auth.onAuthStateChange.map((state) => state.session);
  }

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'nickname': nickname},
    );
    return response.session == null
        ? SignUpResult.needsEmailConfirmation
        : SignUpResult.signedIn;
  }

  Future<void> signOut() => _client.auth.signOut();
}

/// 로그인 실패 원인을 사용자에게 보여줄 문장으로 바꾼다.
String describeAuthError(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return '이메일 또는 비밀번호가 맞지 않습니다.';
    }
    if (message.contains('email not confirmed')) {
      return '메일함에서 가입 확인 링크를 먼저 눌러 주세요.';
    }
    if (message.contains('already registered')) {
      return '이미 가입된 이메일입니다.';
    }
    if (message.contains('password')) {
      return '비밀번호는 6자 이상이어야 합니다.';
    }
    return error.message;
  }
  return '네트워크 상태를 확인한 뒤 다시 시도해 주세요.';
}
