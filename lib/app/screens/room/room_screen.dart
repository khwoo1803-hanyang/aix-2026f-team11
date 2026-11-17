import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/room_provider.dart';
import '../chat/chat_sheet.dart';

/// 여행방 대시보드. 지금은 초대 코드와 멤버 목록만 보여준다.
class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider(roomId));
    final members = ref.watch(roomMembersProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: Text(room.value?.name ?? '여행방')),
      floatingActionButton: ChatButton(roomId: roomId),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(roomMembersProvider(roomId).future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            room.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('여행방 정보를 불러오지 못했습니다.'),
              data: (data) => Card(
                child: ListTile(
                  title: const Text('초대 코드'),
                  subtitle: Text(
                    data.inviteCode,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  trailing: IconButton(
                    tooltip: '복사',
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: data.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('초대 코드를 복사했습니다.')),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('멤버', style: Theme.of(context).textTheme.titleMedium),
            members.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Text('멤버 목록을 불러오지 못했습니다.'),
              data: (list) => Column(
                children: [
                  for (final member in list)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(member.nickname),
                      trailing: member.isOwner ? const Text('방장') : null,
                    ),
                  Text('${list.length}명 참여 중'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
