import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/travel_room.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../services/room_service.dart';
import '../../travel_theme.dart';
import '../room/room_screen.dart';
import 'room_onboarding_screen.dart';

class RoomListScreen extends ConsumerWidget {
  const RoomListScreen({super.key});

  void _openRoom(BuildContext context, String roomId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => RoomScreen(roomId: roomId)));
  }

  Future<void> _createRoom(BuildContext context) async {
    final room = await Navigator.of(context).push<TravelRoom>(
      MaterialPageRoute(builder: (_) => const RoomOnboardingScreen()),
    );
    if (room != null && context.mounted) _openRoom(context, room.id);
  }

  Future<void> _joinRoom(BuildContext context, WidgetRef ref) async {
    final input = await _askText(
      context,
      title: '초대 코드로 입장',
      label: '초대 코드 6자리',
      confirm: '입장',
    );
    if (input == null || !context.mounted) return;
    final code = normalizeInviteCode(input);
    if (!isValidInviteCode(code)) {
      _showMessage(context, '초대 코드는 영문과 숫자 6자리입니다.');
      return;
    }
    try {
      final roomId = await ref.read(roomServiceProvider).joinByCode(code);
      ref.invalidate(myRoomsProvider);
      if (context.mounted) _openRoom(context, roomId);
    } on InvalidInviteCodeException {
      if (context.mounted) _showMessage(context, '없는 초대 코드입니다. 다시 확인해 주세요.');
    } catch (_) {
      if (context.mounted) _showMessage(context, '입장하지 못했습니다.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(myRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('여행 계획'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: TravelWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(myRoomsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
            children: [
              const TravelHeading(
                '함께 만드는 여행',
                description: '새 여행을 시작하거나 받은 초대 코드로 함께하세요.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _createRoom(context),
                icon: const Icon(Icons.add),
                label: const Text('여행방 만들기'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _joinRoom(context, ref),
                icon: const Icon(Icons.vpn_key_outlined, size: 18),
                label: const Text('초대 코드로 입장'),
              ),
              const SizedBox(height: 28),
              Text('내 여행방', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              rooms.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Card(
                  child: ListTile(
                    title: const Text('여행방 목록을 불러오지 못했습니다.'),
                    trailing: TextButton(
                      onPressed: () => ref.invalidate(myRoomsProvider),
                      child: const Text('다시 시도'),
                    ),
                  ),
                ),
                data: (list) => list.isEmpty
                    ? const Card(
                        child: ListTile(
                          leading: Icon(Icons.luggage_outlined),
                          title: Text('아직 여행방이 없어요.'),
                        ),
                      )
                    : Column(
                        children: [
                          for (final room in list)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: travelTint,
                                    foregroundColor: travelBlue,
                                    child: Icon(Icons.luggage_outlined),
                                  ),
                                  title: Text(
                                    room.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  subtitle: Text('초대 코드 ${room.inviteCode}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openRoom(context, room.id),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String label,
  required String confirm,
  String? hint,
}) {
  var value = '';
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        autofocus: true,
        onChanged: (input) => value = input.trim(),
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(value.isEmpty ? null : value);
          },
          child: Text(confirm),
        ),
      ],
    ),
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
