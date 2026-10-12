import 'package:flutter/material.dart';

enum CalculatorNoticeKind { warning, error }

class CalculatorNotice extends StatelessWidget {
  const CalculatorNotice({
    super.key,
    required this.message,
    this.kind = CalculatorNoticeKind.error,
  });

  final String message;
  final CalculatorNoticeKind kind;

  @override
  Widget build(BuildContext context) {
    final isError = kind == CalculatorNoticeKind.error;
    final foreground = isError
        ? const Color(0xFF923D35)
        : const Color(0xFF7D5A20);

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFAEDE9) : const Color(0xFFFBF3DE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: foreground,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
