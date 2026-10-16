/// Узлы AST разобранного выражения и типы ошибок.
/// Не менять без обсуждения.
sealed class ExpressionNode {
  const ExpressionNode();
}

final class NumberNode extends ExpressionNode {
  const NumberNode(this.value);

  final double value;
}

final class UnaryOpNode extends ExpressionNode {
  const UnaryOpNode(this.operator, this.operand);

  /// Только '-'.
  final String operator;
  final ExpressionNode operand;
}

final class BinaryOpNode extends ExpressionNode {
  const BinaryOpNode(this.operator, this.left, this.right);

  /// Одно из: '+', '-', '*', '/', '%', '^'.
  final String operator;
  final ExpressionNode left;
  final ExpressionNode right;
}

final class FunctionNode extends ExpressionNode {
  const FunctionNode(this.name, this.argument);

  /// Одно из: 'sin', 'cos', 'sqrt', 'floor', 'ceil'.
  final String name;
  final ExpressionNode argument;
}

/// Режим углов для тригонометрических функций.
enum AngleMode { deg, rad }

/// Синтаксическая ошибка разбора (бросает парсер).
class ParseException implements Exception {
  const ParseException(this.message);

  final String message;

  @override
  String toString() => 'ParseException: $message';
}

/// Математическая ошибка при корректном синтаксисе (бросает вычислитель).
class EvaluationException implements Exception {
  const EvaluationException(this.message);

  final String message;

  @override
  String toString() => 'EvaluationException: $message';
}
