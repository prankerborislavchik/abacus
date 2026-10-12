import 'package:flutter/material.dart';

import 'calculator_key.dart';

class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({super.key, this.onKeyPressed});

  final ValueChanged<String>? onKeyPressed;

  static const _rows = [
    [
      ('MC', 'MC', CalculatorKeyTone.function),
      ('M+', 'M+', CalculatorKeyTone.function),
      ('AC', 'AC', CalculatorKeyTone.function),
      ('⌫', 'Удалить символ', CalculatorKeyTone.function),
    ],
    [
      ('sin', 'Синус', CalculatorKeyTone.function),
      ('cos', 'Косинус', CalculatorKeyTone.function),
      ('xʸ', 'Возведение в степень', CalculatorKeyTone.function),
      ('√x', 'Квадратный корень', CalculatorKeyTone.function),
    ],
    [
      ('⌊x⌋', 'Округление вниз', CalculatorKeyTone.function),
      ('⌈x⌉', 'Округление вверх', CalculatorKeyTone.function),
      ('(', 'Открывающая скобка', CalculatorKeyTone.function),
      (')', 'Закрывающая скобка', CalculatorKeyTone.function),
    ],
    [
      ('7', '7', CalculatorKeyTone.digit),
      ('8', '8', CalculatorKeyTone.digit),
      ('9', '9', CalculatorKeyTone.digit),
      ('÷', 'Деление', CalculatorKeyTone.operation),
    ],
    [
      ('4', '4', CalculatorKeyTone.digit),
      ('5', '5', CalculatorKeyTone.digit),
      ('6', '6', CalculatorKeyTone.digit),
      ('×', 'Умножение', CalculatorKeyTone.operation),
    ],
    [
      ('1', '1', CalculatorKeyTone.digit),
      ('2', '2', CalculatorKeyTone.digit),
      ('3', '3', CalculatorKeyTone.digit),
      ('−', 'Вычитание', CalculatorKeyTone.operation),
    ],
    [
      ('0', '0', CalculatorKeyTone.digit),
      ('.', 'Десятичная точка', CalculatorKeyTone.digit),
      ('%', 'Остаток от деления', CalculatorKeyTone.operation),
      ('+', 'Сложение', CalculatorKeyTone.operation),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        for (final row in _rows)
          Row(
            spacing: 8,
            children: [
              for (final (label, semanticLabel, tone) in row)
                Expanded(
                  child: CalculatorKey(
                    label: label,
                    semanticLabel: semanticLabel,
                    tone: tone,
                    onPressed: onKeyPressed == null
                        ? null
                        : () => onKeyPressed!(label),
                  ),
                ),
            ],
          ),
        CalculatorKey(
          label: '=',
          semanticLabel: 'Вычислить',
          tone: CalculatorKeyTone.equals,
          onPressed: onKeyPressed == null ? null : () => onKeyPressed!('='),
        ),
      ],
    );
  }
}
