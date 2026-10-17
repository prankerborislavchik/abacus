import 'dart:math' as math;

import 'expression_node.dart';

/// Множитель перевода градусов в радианы. Вычислен заранее,
/// чтобы arg * (pi / 180) не переполнялся для больших углов.
const double _degToRad = math.pi / 180;

/// Вычисляет AST до конечного double. Бросает [EvaluationException]
/// при математических ошибках и при NaN/бесконечности.
double evaluate(ExpressionNode node, {AngleMode angleMode = AngleMode.deg}) =>
    _eval(node, angleMode);

double _eval(ExpressionNode node, AngleMode mode) {
  final result = switch (node) {
    NumberNode(:final value) => value,
    UnaryOpNode(:final operand) => -_eval(operand, mode),
    BinaryOpNode(:final operator, :final left, :final right) => _binary(
      operator,
      _eval(left, mode),
      _eval(right, mode),
    ),
    FunctionNode(:final name, :final argument) => _function(
      name,
      _eval(argument, mode),
      mode,
    ),
  };
  // Конечность проверяется на каждом узле: родительская операция
  // не должна скрывать ошибку дочернего (1/(10^400), ((-1)^0.5)^0).
  if (result.isNaN || result.isInfinite) {
    throw const EvaluationException('Результат не является конечным числом');
  }
  return result;
}

double _binary(String op, double l, double r) => switch (op) {
  '+' => l + r,
  '-' => l - r,
  '*' => l * r,
  '/' => r == 0 ? throw const EvaluationException('Деление на ноль') : l / r,
  '%' =>
    r == 0
        ? throw const EvaluationException('Остаток от деления на ноль')
        : l.remainder(r), // знак делимого, как требует спека
  '^' => math.pow(l, r).toDouble(),
  _ => throw EvaluationException('Неизвестный оператор: $op'),
};

double _function(String name, double arg, AngleMode mode) {
  final radians = mode == AngleMode.deg ? arg * _degToRad : arg;
  return switch (name) {
    'sin' => math.sin(radians),
    'cos' => math.cos(radians),
    'sqrt' =>
      arg < 0
          ? throw const EvaluationException('Корень из отрицательного числа')
          : math.sqrt(arg),
    'floor' => arg.floorToDouble(),
    'ceil' => arg.ceilToDouble(),
    _ => throw EvaluationException('Неизвестная функция: $name'),
  };
}
