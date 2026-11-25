import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/destination.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/destination_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../services/destination_service.dart';
import '../chat/chat_sheet.dart';

class DestinationVoteScreen extends ConsumerWidget {
  const DestinationVoteScreen({super.key, required this.roomId});

  final String roomId;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on DestinationException catch (error) {
      if (context.mounted) _showMessage(context, error.message);
    } catch (_) {
      if (context.mounted) _showMessage(context, '네트워크 상태를 확인해 주세요.');
    }
  }

  Future<void> _addDestination(BuildContext context, WidgetRef ref) async {
    final input = await showDialog<({String name, String reason})>(
      context: context,
      builder: (_) => const _AddDestinationDialog(),
    );
    if (input == null || !context.mounted) return;
    await _run(
      context,
      () => ref
          .read(destinationServiceProvider)
          .addDestination(
            roomId: roomId,
            name: input.name,
            reason: input.reason,
          ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    Destination destination,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('여행지 확정'),
        content: Text('${destination.name}(으)로 확정할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확정'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(
      context,
      () => ref.read(destinationServiceProvider).confirm(destination.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider(roomId)).value;
    final destinations = ref.watch(roomDestinationsProvider(roomId));
    final votes = ref.watch(roomVotesProvider(roomId)).value ?? const [];
    final members = ref.watch(roomMembersProvider(roomId)).value ?? const [];
    final myId = ref.watch(currentUserIdProvider);

    final nicknames = {for (final m in members) m.userId: m.nickname};
    final tallies = tallyVotes(votes, myId);
    final isOwner = room != null && room.ownerId == myId;
    final confirmedId = room?.confirmedDestinationId;

    return Scaffold(
      appBar: AppBar(title: const Text('여행지 투표')),
      floatingActionButton: ChatButton(roomId: roomId),
      body: destinations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('후보를 불러오지 못했습니다.')),
        data: (list) {
          final mine = list.where((d) => d.proposedBy == myId).length;
          final confirmed = list.where((d) => d.id == confirmedId).firstOrNull;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              if (confirmed != null)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.flag),
                    title: Text('확정된 여행지: ${confirmed.name}'),
                  ),
                ),
              Text(
                '후보마다 찬성·보통·반대를 골라 주세요. 찬성이 ${members.length}명 중 과반이면 방장이 확정할 수 있어요.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: mine >= maxDestinationsPerMember
                    ? null
                    : () => _addDestination(context, ref),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Text('후보 올리기 ($mine/$maxDestinationsPerMember)'),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('아직 후보가 없어요.', textAlign: TextAlign.center),
                ),
              for (final destination in list)
                _DestinationCard(
                  destination: destination,
                  proposer: nicknames[destination.proposedBy] ?? '알 수 없음',
                  tally: tallies[destination.id] ?? const VoteTally(),
                  memberCount: members.length,
                  isOwner: isOwner,
                  isConfirmed: destination.id == confirmedId,
                  onVote: (choice) => _run(
                    context,
                    () => ref
                        .read(destinationServiceProvider)
                        .vote(destinationId: destination.id, choice: choice),
                  ),
                  onConfirm: () => _confirm(context, ref, destination),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.destination,
    required this.proposer,
    required this.tally,
    required this.memberCount,
    required this.isOwner,
    required this.isConfirmed,
    required this.onVote,
    required this.onConfirm,
  });

  final Destination destination;
  final String proposer;
  final VoteTally tally;
  final int memberCount;
  final bool isOwner;
  final bool isConfirmed;
  final ValueChanged<VoteChoice> onVote;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final reason = destination.reason;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    destination.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isConfirmed) const Chip(label: Text('확정')),
              ],
            ),
            Text('$proposer 님 추천${reason == null ? '' : ' · $reason'}'),
            const SizedBox(height: 8),
            Text(
              '찬성 ${tally.agree} · 보통 ${tally.neutral} · 반대 ${tally.disagree}',
              key: Key('tally-${destination.id}'),
            ),
            const SizedBox(height: 8),
            SegmentedButton<VoteChoice>(
              segments: [
                for (final choice in VoteChoice.values)
                  ButtonSegment(value: choice, label: Text(choice.label)),
              ],
              selected: {?tally.mine},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) onVote(selection.first);
              },
            ),
            if (isOwner && !isConfirmed) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: tally.hasMajority(memberCount) ? onConfirm : null,
                  child: const Text('이 여행지로 확정'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddDestinationDialog extends StatefulWidget {
  const _AddDestinationDialog();

  @override
  State<_AddDestinationDialog> createState() => _AddDestinationDialogState();
}

class _AddDestinationDialogState extends State<_AddDestinationDialog> {
  final _name = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('여행지 후보 올리기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('destination-name'),
            controller: _name,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: '여행지',
              hintText: '예: 강릉',
            ),
          ),
          TextField(
            key: const Key('destination-reason'),
            controller: _reason,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: '추천 이유 (선택)',
              hintText: '예: 바다도 보고 차로 2시간 반이면 가요',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context)
                .pop((name: name, reason: _reason.text.trim()));
          },
          child: const Text('올리기'),
        ),
      ],
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
