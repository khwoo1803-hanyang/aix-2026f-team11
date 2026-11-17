import 'package:flutter_test/flutter_test.dart';

import 'package:travel_planner/app/app.dart';

void main() {
  testWidgets('Supabase 설정이 없으면 안내 문구를 표시한다', (tester) async {
    await tester.pumpWidget(
      const TravelPlannerApp(isSupabaseConfigured: false),
    );

    expect(find.text('env.json에 Supabase 설정을 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('Supabase 설정이 있으면 적용 문구를 표시한다', (tester) async {
    await tester.pumpWidget(
      const TravelPlannerApp(isSupabaseConfigured: true),
    );

    expect(find.text('Supabase 설정이 적용되었습니다.'), findsOneWidget);
  });
}
