import 'package:flutter_test/flutter_test.dart';

import 'package:travel_planner/models/travel_room.dart';
import 'package:travel_planner/services/room_service.dart';

void main() {
  group('초대 코드', () {
    test('공백, 하이픈, 소문자를 정리한다', () {
      expect(normalizeInviteCode(' ab3-k9z '), 'AB3K9Z');
    });

    test('영문 대문자와 2~9 숫자 6자리만 유효하다', () {
      expect(isValidInviteCode('AB3K9Z'), isTrue);
      expect(isValidInviteCode('AB3K9'), isFalse);
      expect(isValidInviteCode('AB3K90'), isFalse);
      expect(isValidInviteCode('AB3K9Z1'), isFalse);
    });
  });

  test('멤버 정보에서 닉네임과 방장 여부를 읽는다', () {
    final member = RoomMember.fromJson({
      'user_id': 'u1',
      'role': 'owner',
      'profiles': {'nickname': '현우'},
    });

    expect(member.nickname, '현우');
    expect(member.isOwner, isTrue);
  });
}
