import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/recommendation.dart';
import '../../../providers/condition_provider.dart';
import '../../../providers/destination_provider.dart';
import '../../../providers/recommendation_provider.dart';
import '../../../services/destination_service.dart';
import '../../../services/recommendation_service.dart';
import '../chat/chat_sheet.dart';

/// AI 여행지 추천 화면 (활동지 #7).
/// 저장된 여행 조건과 투표 현황으로 국내 여행지 3곳을 추천받고, 마음에 들면 투표 후보로 올린다.
class RecommendationScreen extends ConsumerStatefulWidget {
  const RecommendationScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<RecommendationScreen> createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen> {
  bool _requesting = false;
  final _adding = <String>{};

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    String message;
    try {
      final count = await ref
          .read(recommendationServiceProvider)
          .request(widget.roomId);
      message = '여행지 $count곳을 추천받았어요.';
    } on RecommendationException catch (error) {
      message = error.message;
    } catch (_) {
      message = '네트워크 상태를 확인해 주세요.';
    }
    if (!mounted) return;
    setState(() => _requesting = false);
    _showMessage(message);
  }

  Future<void> _addCandidate(Recommendation item) async {
    setState(() => _adding.add(item.id));
    String message;
    try {
      // 후보 이유는 DB에서 200자까지 받는다.
      final reason = 'AI 추천 · ${item.reason}';
      await ref
          .read(destinationServiceProvider)
          .addDestination(
            roomId: widget.roomId,
            name: item.name,
            reason: reason.length > 200 ? reason.substring(0, 200) : reason,
          );
      message = '${item.name}을(를) 투표 후보로 올렸어요.';
    } on DestinationException catch (error) {
      message = error.message;
    } catch (_) {
      message = '네트워크 상태를 확인해 주세요.';
    }
    if (!mounted) return;
    setState(() => _adding.remove(item.id));
    _showMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = ref.watch(
      roomRecommendationsProvider(widget.roomId),
    );
    final conditions =
        ref.watch(roomConditionsProvider(widget.roomId)).value ?? const [];
    final candidateNames = {
      for (final d
          in ref.watch(roomDestinationsProvider(widget.roomId)).value ??
              const [])
        d.name.trim().toLowerCase(),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('AI 여행지 추천')),
      floatingActionButton: ChatButton(roomId: widget.roomId),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Text(
            conditions.isEmpty
                ? '추천을 받으려면 먼저 여행 조건을 정리하거나 직접 입력해 주세요.'
                : '정리된 조건 ${conditions.length}개와 투표 현황을 보고 AI가 국내 여행지 3곳을 추천해요. '
                      '거리, 가격, 운영 시간은 꼭 따로 확인해 주세요.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _requesting || conditions.isEmpty ? null : _request,
            icon: _requesting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_requesting ? '추천받는 중... (최대 1분)' : 'AI 추천 받기'),
          ),
          const SizedBox(height: 12),
          ...recommendations.when(
            loading: () => const [Center(child: CircularProgressIndicator())],
            error: (_, _) => const [Center(child: Text('추천을 불러오지 못했습니다.'))],
            data: (list) => list.isEmpty
                ? const [Center(child: Text('아직 받은 추천이 없어요.'))]
                : [
                    for (final item in list)
                      _RecommendationCard(
                        item: item,
                        added: candidateNames.contains(
                          item.name.trim().toLowerCase(),
                        ),
                        adding: _adding.contains(item.id),
                        onAdd: () => _addCandidate(item),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.item,
    required this.added,
    required this.adding,
    required this.onAdd,
  });

  final Recommendation item;
  final bool added;
  final bool adding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14, child: Text('${item.rank}')),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.name, style: theme.textTheme.titleLarge),
                ),
                if (item.region != null)
                  Text(item.region!, style: TextStyle(color: muted)),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.reason),
            if (item.matches.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in item.matches)
                    Tooltip(
                      message: m.note,
                      child: Chip(
                        avatar: Icon(_iconFor(m.status), size: 16),
                        label: Text('${m.field.label} ${m.status.label}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ],
            if (item.caution != null) ...[
              const SizedBox(height: 8),
              Text('확인할 점 · ${item.caution}', style: TextStyle(color: muted)),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: added
                  ? const Chip(label: Text('후보에 있음'))
                  : OutlinedButton.icon(
                      onPressed: adding ? null : onAdd,
                      icon: const Icon(Icons.how_to_vote_outlined),
                      label: const Text('투표 후보로 올리기'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(MatchStatus status) => switch (status) {
    MatchStatus.match => Icons.check_circle_outline,
    MatchStatus.partial => Icons.change_circle_outlined,
    MatchStatus.unknown => Icons.help_outline,
  };
}
