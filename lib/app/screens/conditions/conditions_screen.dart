import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/trip_condition.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/condition_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../services/condition_service.dart';
import '../chat/chat_sheet.dart';

/// 채팅에서 정리한 여행 조건을 출처 메시지와 함께 보여준다.
class ConditionsScreen extends ConsumerStatefulWidget {
  const ConditionsScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ConditionsScreen> createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends ConsumerState<ConditionsScreen> {
  bool _extracting = false;

  Future<void> _extract() async {
    setState(() => _extracting = true);
    String message;
    try {
      final found = await ref
          .read(conditionServiceProvider)
          .extractFromChat(widget.roomId);
      message = found == 0
          ? '대화에서 조건을 찾지 못했어요. 채팅에 날짜, 예산 같은 조건을 적어 보세요.'
          : '조건 $found개를 정리했어요.';
    } on ConditionException catch (error) {
      message = error.message;
    } catch (_) {
      message = '네트워크 상태를 확인해 주세요.';
    }
    if (!mounted) return;
    setState(() => _extracting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final conditions = ref.watch(roomConditionsProvider(widget.roomId));
    final messages = ref.watch(roomMessagesProvider(widget.roomId)).value ?? const [];
    final members = ref.watch(roomMembersProvider(widget.roomId)).value ?? const [];

    final nicknames = {for (final m in members) m.userId: m.nickname};
    final sources = {
      for (final m in messages) m.id: '${nicknames[m.userId] ?? '알 수 없음'}: ${m.content}',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('여행 조건')),
      floatingActionButton: ChatButton(roomId: widget.roomId),
      body: conditions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('조건을 불러오지 못했습니다.')),
        data: (list) {
          final byField = {for (final c in list) c.field: c};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              const Text('채팅 내용을 AI가 읽고 여행 조건을 정리해요. 출처 메시지도 함께 보여 드려요.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _extracting ? null : _extract,
                icon: _extracting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_extracting ? '정리하는 중...' : '채팅에서 조건 정리'),
              ),
              const SizedBox(height: 12),
              for (final field in ConditionField.values)
                _ConditionTile(
                  field: field,
                  condition: byField[field],
                  source: sources[byField[field]?.sourceMessageId],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  const _ConditionTile({
    required this.field,
    required this.condition,
    required this.source,
  });

  final ConditionField field;
  final TripCondition? condition;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final condition = this.condition;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: ListTile(
        title: Text(field.label, style: Theme.of(context).textTheme.labelLarge),
        subtitle: condition == null
            ? Text('아직 없음', style: TextStyle(color: muted))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condition.value,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (source != null)
                    Text(
                      '출처 · $source',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted),
                    ),
                ],
              ),
        trailing: condition != null && condition.inferred
            ? const Tooltip(
                message: '대화로 미루어 짐작한 값이에요',
                child: Chip(label: Text('AI 추측')),
              )
            : null,
      ),
    );
  }
}
