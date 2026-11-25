import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/chat_message.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../services/chat_service.dart';

/// 여행방 어느 화면에서든 오른쪽 아래 버튼으로 여는 채팅창.
Future<void> showChatSheet(BuildContext context, String roomId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.85,
      child: ChatSheet(roomId: roomId),
    ),
  );
}

class ChatButton extends StatelessWidget {
  const ChatButton({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: '채팅',
      onPressed: () => showChatSheet(context, roomId),
      child: const Icon(Icons.chat_bubble_outline),
    );
  }
}

class ChatSheet extends ConsumerStatefulWidget {
  const ChatSheet({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<ChatSheet> {
  final _input = TextEditingController();
  final _requestedMembers = <String>{};
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(chatServiceProvider)
          .send(roomId: widget.roomId, content: text);
      _input.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('메시지를 보내지 못했습니다.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// 채팅 도중 새로 들어온 멤버의 닉네임을 한 번만 다시 불러온다.
  void _refreshMembersFor(String userId) {
    if (_requestedMembers.add(userId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(roomMembersProvider(widget.roomId));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(roomMessagesProvider(widget.roomId));
    final members = ref.watch(roomMembersProvider(widget.roomId)).value ?? [];
    final nicknames = {for (final m in members) m.userId: m.nickname};
    final myId = ref.watch(currentUserIdProvider);

    return Column(
      children: [
        Text('여행방 채팅', style: Theme.of(context).textTheme.titleMedium),
        const Divider(),
        Expanded(
          child: messages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('메시지를 불러오지 못했습니다.')),
            data: (list) {
              if (list.isEmpty) {
                return const Center(child: Text('첫 메시지를 보내 보세요.'));
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final message = list[list.length - 1 - index];
                  final nickname = nicknames[message.userId];
                  if (nickname == null) _refreshMembersFor(message.userId);
                  return _MessageBubble(
                    message: message,
                    nickname: nickname ?? '알 수 없음',
                    isMine: message.userId == myId,
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              8,
              8 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat-input'),
                    controller: _input,
                    maxLength: maxMessageLength,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: '메시지 입력',
                      counterText: '',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '보내기',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.nickname,
    required this.isMine,
  });

  final ChatMessage message;
  final String nickname;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Text(nickname, style: Theme.of(context).textTheme.labelSmall),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isMine
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(message.content),
                ),
              ),
            ),
            Text(time, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
