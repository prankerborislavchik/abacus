import 'package:flutter/material.dart';

enum CalculatorKeyTone { digit, function, operation, equals }

class CalculatorKey extends StatelessWidget {
  const CalculatorKey({
    super.key,
    required this.label,
    required this.semanticLabel,
    this.tone = CalculatorKeyTone.digit,
    this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final CalculatorKeyTone tone;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      CalculatorKeyTone.digit => const Color(0xFFF4F5F0),
      CalculatorKeyTone.function => const Color(0xFFEBEEE5),
      CalculatorKeyTone.operation => const Color(0xFFDDE7D5),
      CalculatorKeyTone.equals => const Color(0xFF405B45),
    };
    final foreground = tone == CalculatorKeyTone.equals
        ? const Color(0xFFFAFFF5)
        : const Color(0xFF2D422F);

    return SizedBox(
      height: 48,
      child: Tooltip(
        message: semanticLabel,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background,
            disabledForegroundColor: foreground,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontSize: tone == CalculatorKeyTone.function ? 16 : 23,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: Text(label, semanticsLabel: semanticLabel),
        ),
      ),
    );
  }
}
