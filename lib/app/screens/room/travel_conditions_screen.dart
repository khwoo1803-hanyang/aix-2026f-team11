import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/travel_conditions.dart';
import '../../../providers/travel_conditions_provider.dart';
import '../../../services/travel_conditions_service.dart';

class TravelConditionsScreen extends ConsumerWidget {
  const TravelConditionsScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditions = ref.watch(travelConditionsProvider(roomId));
    return Scaffold(
      appBar: AppBar(title: const Text('여행 조건')),
      body: conditions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('여행 조건을 불러오지 못했습니다.'),
              TextButton(
                onPressed: () =>
                    ref.invalidate(travelConditionsProvider(roomId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (data) => _ConditionsForm(roomId: roomId, initial: data),
      ),
    );
  }
}

class _ConditionsForm extends ConsumerStatefulWidget {
  const _ConditionsForm({required this.roomId, required this.initial});

  final String roomId;
  final TravelConditions initial;

  @override
  ConsumerState<_ConditionsForm> createState() => _ConditionsFormState();
}

class _ConditionsFormState extends ConsumerState<_ConditionsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _departure = TextEditingController(text: widget.initial.departure);
  late final _travelerCount = TextEditingController(
    text: widget.initial.travelerCount?.toString(),
  );
  late final _budget = TextEditingController(
    text: widget.initial.budgetPerPersonKrw?.toString(),
  );
  late final _transport = TextEditingController(text: widget.initial.transport);
  late final _activities = TextEditingController(
    text: widget.initial.preferredActivities,
  );
  late DateTimeRange? _dates = widget.initial.startDate == null
      ? null
      : DateTimeRange(
          start: widget.initial.startDate!,
          end: widget.initial.endDate!,
        );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _departure.dispose();
    _travelerCount.dispose();
    _budget.dispose();
    _transport.dispose();
    _activities.dispose();
    super.dispose();
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _chooseDates() async {
    final dates = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      initialDateRange: _dates,
      helpText: '여행 기간 선택',
      saveText: '선택',
    );
    if (mounted && dates != null) setState(() => _dates = dates);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(travelConditionsServiceProvider)
          .save(
            widget.roomId,
            TravelConditions(
              departure: _optionalText(_departure),
              startDate: _dates?.start,
              endDate: _dates?.end,
              travelerCount: int.tryParse(_travelerCount.text),
              budgetPerPersonKrw: int.tryParse(_budget.text),
              transport: _optionalText(_transport),
              preferredActivities: _optionalText(_activities),
              revision: widget.initial.revision,
            ),
          );
    } on TravelConditionsConflict {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '다른 멤버가 먼저 저장했습니다. 화면을 다시 열어 최신 조건을 확인해 주세요.';
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '여행 조건을 저장하지 못했습니다. 다시 시도해 주세요.';
      });
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('여행 조건을 저장했습니다.')));
    Navigator.of(context).pop();
  }

  TextFormField _numberField({
    required TextEditingController controller,
    required String label,
    required int min,
    required int max,
    required String error,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      enabled: !_saving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final number = int.tryParse(value);
        return number == null || number < min || number > max ? error : null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = _dates;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _departure,
              enabled: !_saving,
              maxLength: 100,
              decoration: const InputDecoration(labelText: '출발지'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range_outlined),
              title: const Text('여행 기간'),
              subtitle: Text(
                dates == null
                    ? '기간 선택'
                    : '${TravelConditions.formatDate(dates.start)} ~ '
                          '${TravelConditions.formatDate(dates.end)}',
              ),
              onTap: _saving ? null : _chooseDates,
              trailing: dates == null
                  ? null
                  : IconButton(
                      tooltip: '여행 기간 지우기',
                      onPressed: _saving
                          ? null
                          : () => setState(() => _dates = null),
                      icon: const Icon(Icons.clear),
                    ),
            ),
            _numberField(
              controller: _travelerCount,
              label: '여행 인원',
              min: 1,
              max: 1000,
              error: '1~1,000명 사이로 입력해 주세요.',
            ),
            _numberField(
              controller: _budget,
              label: '1인당 예산 (원)',
              min: 0,
              max: 2147483647,
              error: '0~2,147,483,647원 사이로 입력해 주세요.',
            ),
            TextFormField(
              controller: _transport,
              enabled: !_saving,
              maxLength: 100,
              decoration: const InputDecoration(labelText: '이동 수단'),
            ),
            TextFormField(
              controller: _activities,
              enabled: !_saving,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '선호 활동'),
            ),
            if (_error case final message?)
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '저장 중…' : '저장'),
            ),
          ],
        ),
      ),
    );
  }
}
