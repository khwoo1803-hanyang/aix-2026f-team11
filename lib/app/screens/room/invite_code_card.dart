import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../travel_theme.dart';

class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key, required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    String message;
    try {
      await Clipboard.setData(ClipboardData(text: code));
      message = '초대 코드를 복사했습니다.';
    } catch (_) {
      message = '코드를 복사하지 못했습니다. 코드에 표시된 문자를 공유해 주세요.';
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: travelGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('초대 코드', style: TextStyle(color: travelMuted)),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      code,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy_outlined, size: 16),
              label: const Text('복사'),
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
