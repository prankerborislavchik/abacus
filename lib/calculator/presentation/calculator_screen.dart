import 'package:flutter/material.dart';

import 'widgets/calculator_keypad.dart';
import 'widgets/calculator_notice.dart';
import 'widgets/expression_display.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({
    super.key,
    this.expression = '',
    this.result,
    this.memory,
    this.notice,
  });

  final String expression;
  final String? result;
  final String? memory;
  final CalculatorNotice? notice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEFFFC),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFE0E5DA)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0926392C),
                              blurRadius: 32,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Header(memory: memory),
                              const SizedBox(height: 24),
                              ExpressionDisplay(
                                expression: expression,
                                result: result,
                              ),
                              if (notice case final message?) ...[
                                const SizedBox(height: 12),
                                message,
                              ],
                              const SizedBox(height: 20),
                              const CalculatorKeypad(),
                              const SizedBox(height: 20),
                              const Text(
                                'Предпросмотр · ввод пока недоступен',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF657261),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.memory});

  final String? memory;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        const Text(
          'Abacus',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              'Память  ${memory ?? '—'}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF50634D)),
            ),
          ),
        ),
      ],
    );
  }
}
