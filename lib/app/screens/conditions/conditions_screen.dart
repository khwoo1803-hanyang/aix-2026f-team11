import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/trip_condition.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/condition_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../services/condition_service.dart';
import '../chat/chat_sheet.dart';

/// 여행 조건 확인·수정 화면 (활동지 #5, #6).
/// AI가 채팅에서 정리한 조건을 출처와 함께 보여주고, 멤버가 직접 고칠 수 있다.
class ConditionsScreen extends ConsumerStatefulWidget {
  const ConditionsScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ConditionsScreen> createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends ConsumerState<ConditionsScreen> {
  bool _extracting = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _extract() async {
    setState(() => _extracting = true);
    String message;
    try {
      final result = await ref
          .read(conditionServiceProvider)
          .extractFromChat(widget.roomId);
      final keptNote = result.kept > 0
          ? ' 직접 고친 ${result.kept}개는 그대로 뒀어요.'
          : '';
      message = result.found == 0
          ? result.kept > 0
                ? '새로 바뀐 조건이 없어요.$keptNote'
                : '대화에서 조건을 찾지 못했어요. 채팅에 날짜, 예산 같은 조건을 적거나 직접 입력해 보세요.'
          : '조건 ${result.found}개를 정리했어요.$keptNote';
    } on ConditionException catch (error) {
      message = error.message;
    } catch (_) {
      message = '네트워크 상태를 확인해 주세요.';
    }
    if (!mounted) return;
    setState(() => _extracting = false);
    _showMessage(message);
  }

  Future<void> _edit(ConditionField field, TripCondition? current) async {
    final action = await showDialog<_EditAction>(
      context: context,
      builder: (_) =>
          _EditConditionDialog(field: field, initial: current?.value),
    );
    if (action == null || !mounted) return;
    final service = ref.read(conditionServiceProvider);
    try {
      switch (action) {
        case _Save(:final value):
          await service.save(roomId: widget.roomId, field: field, value: value);
        case _Clear():
          await service.clear(roomId: widget.roomId, field: field);
      }
    } on ConditionException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('네트워크 상태를 확인해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final conditions = ref.watch(roomConditionsProvider(widget.roomId));
    final messages =
        ref.watch(roomMessagesProvider(widget.roomId)).value ?? const [];
    final members =
        ref.watch(roomMembersProvider(widget.roomId)).value ?? const [];

    final nicknames = {for (final m in members) m.userId: m.nickname};
    final sources = {
      for (final m in messages)
        m.id: '${nicknames[m.userId] ?? '알 수 없음'}: ${m.content}',
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
              const Text(
                '채팅 내용을 AI가 읽고 여행 조건을 정리해요. 항목을 누르면 직접 고칠 수 있고, 직접 고친 값은 AI가 바꾸지 않아요.',
              ),
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
                  editor: nicknames[byField[field]?.updatedBy],
                  onTap: () => _edit(field, byField[field]),
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
    required this.editor,
    required this.onTap,
  });

  final ConditionField field;
  final TripCondition? condition;
  final String? source;
  final String? editor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final condition = this.condition;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    String? note;
    if (condition != null && condition.manual) {
      note = editor == null ? '직접 입력' : '$editor 님이 직접 입력';
    } else if (source != null) {
      note = '출처 · $source';
    }

    Widget? badge;
    if (condition != null && condition.manual) {
      badge = const Chip(label: Text('직접 입력'));
    } else if (condition != null && condition.inferred) {
      badge = const Tooltip(
        message: '대화로 미루어 짐작한 값이에요',
        child: Chip(label: Text('AI 추측')),
      );
    }

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(field.label, style: Theme.of(context).textTheme.labelLarge),
        subtitle: condition == null
            ? Text('아직 없음 · 눌러서 입력', style: TextStyle(color: muted))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condition.value,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (note != null)
                    Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted),
                    ),
                ],
              ),
        trailing: badge ?? const Icon(Icons.edit_outlined),
      ),
    );
  }
}

sealed class _EditAction {
  const _EditAction();
}

class _Save extends _EditAction {
  const _Save(this.value);

  final String value;
}

class _Clear extends _EditAction {
  const _Clear();
}

class _EditConditionDialog extends StatefulWidget {
  const _EditConditionDialog({required this.field, this.initial});

  final ConditionField field;
  final String? initial;

  @override
  State<_EditConditionDialog> createState() => _EditConditionDialogState();
}

class _EditConditionDialogState extends State<_EditConditionDialog> {
  late final _value = TextEditingController(text: widget.initial);

  static const _hints = {
    ConditionField.people: '예: 4명',
    ConditionField.dates: '예: 8월 둘째 주, 2박 3일',
    ConditionField.departure: '예: 서울',
    ConditionField.transport: '예: 자동차 1대',
    ConditionField.budget: '예: 1인 30만 원',
    ConditionField.activity: '예: 바다, 맛집',
  };

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.field.label} 입력'),
      content: TextField(
        key: const Key('condition-value'),
        controller: _value,
        autofocus: true,
        maxLength: 200,
        decoration: InputDecoration(
          labelText: widget.field.label,
          hintText: _hints[widget.field],
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const _Clear()),
            child: const Text('비우기'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final value = _value.text.trim();
            if (value.isEmpty) return;
            Navigator.of(context).pop(_Save(value));
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
