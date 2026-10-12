import 'package:flutter/material.dart';

class ExpressionDisplay extends StatelessWidget {
  const ExpressionDisplay({super.key, required this.expression, this.result});

  final String expression;
  final String? result;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E9DB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ВЫРАЖЕНИЕ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
                color: Color(0xFF65765E),
              ),
            ),
            Semantics(
              label: 'Выражение',
              child: TextFormField(
                key: ValueKey(expression),
                initialValue: expression,
                readOnly: true,
                showCursor: false,
                enableInteractiveSelection: false,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 36,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: Color(0xFF6E7C66)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const Divider(height: 16, color: Color(0xFFDCE3D4)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Результат',
                  style: TextStyle(fontSize: 13, color: Color(0xFF65765E)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    result ?? '—',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
