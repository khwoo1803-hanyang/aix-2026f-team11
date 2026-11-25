import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../services/room_service.dart';
import '../room/room_screen.dart';

class RoomListScreen extends ConsumerWidget {
  const RoomListScreen({super.key});

  void _openRoom(BuildContext context, String roomId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => RoomScreen(roomId: roomId)));
  }

  Future<void> _createRoom(BuildContext context, WidgetRef ref) async {
    final name = await _askText(
      context,
      title: '여행방 만들기',
      label: '여행방 이름',
      hint: '예: 제주 2박 3일',
      confirm: '만들기',
    );
    if (name == null || !context.mounted) return;
    try {
      final room = await ref.read(roomServiceProvider).createRoom(name: name);
      ref.invalidate(myRoomsProvider);
      if (context.mounted) _openRoom(context, room.id);
    } catch (_) {
      if (context.mounted) _showMessage(context, '여행방을 만들지 못했습니다.');
    }
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
        title: const Text('내 여행방'),
        actions: [
          IconButton(
            tooltip: '초대 코드로 입장',
            icon: const Icon(Icons.vpn_key_outlined),
            onPressed: () => _joinRoom(context, ref),
          ),
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createRoom(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('여행방 만들기'),
      ),
      body: rooms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('여행방 목록을 불러오지 못했습니다.'),
              TextButton(
                onPressed: () => ref.invalidate(myRoomsProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (list) => list.isEmpty
            ? const Center(
                child: Text(
                  '아직 여행방이 없어요.\n여행방을 만들거나 초대 코드로 입장해 보세요.',
                  textAlign: TextAlign.center,
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(myRoomsProvider.future),
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final room = list[index];
                    return ListTile(
                      title: Text(room.name),
                      subtitle: Text('초대 코드 ${room.inviteCode}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openRoom(context, room.id),
                    );
                  },
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
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            Navigator.of(context).pop(value.isEmpty ? null : value);
          },
          child: Text(confirm),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
