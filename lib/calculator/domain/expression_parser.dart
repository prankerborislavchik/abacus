import 'expression_node.dart';

/// Parses once into the shared AST. Instances hold no parsing state.
class ExpressionParser {
  const ExpressionParser();

  ExpressionNode parse(String expression) => _Parser(expression).parse();
}

class _Parser {
  _Parser(this.source);

  final String source;
  int position = 0;

  ExpressionNode parse() {
    final node = _sum();
    _spaces();
    if (position != source.length) _fail('Неожиданный символ');
    return node;
  }

  Never _fail(String message) =>
      throw ParseException('$message (позиция ${position + 1}).');

  void _spaces() {
    while (position < source.length && source[position] == ' ') {
      position++;
    }
  }

  bool _take(String token) {
    _spaces();
    if (!source.startsWith(token, position)) return false;
    position += token.length;
    return true;
  }

  ExpressionNode _sum() {
    var node = _product();
    while (true) {
      if (_take('+')) {
        node = BinaryOpNode('+', node, _product());
      } else if (_take('-')) {
        node = BinaryOpNode('-', node, _product());
      } else {
        return node;
      }
    }
  }

  ExpressionNode _product() {
    var node = _unary();
    while (true) {
      String? operator;
      for (final candidate in ['*', '/', '%']) {
        if (_take(candidate)) {
          operator = candidate;
          break;
        }
      }
      if (operator == null) return node;
      node = BinaryOpNode(operator, node, _unary());
    }
  }

  ExpressionNode _unary() {
    if (_take('-')) return UnaryOpNode('-', _unary());
    return _power();
  }

  ExpressionNode _power() {
    final node = _primary();
    return _take('^') ? BinaryOpNode('^', node, _unary()) : node;
  }

  ExpressionNode _primary() {
    if (_take('(')) {
      final node = _sum();
      if (!_take(')')) _fail('Ожидается закрывающая скобка');
      return node;
    }
    _spaces();
    final start = position;
    while (position < source.length &&
        RegExp('[a-zA-Z]').hasMatch(source[position])) {
      position++;
    }
    if (position != start) {
      final name = source.substring(start, position);
      if (!{'sin', 'cos', 'sqrt', 'floor', 'ceil'}.contains(name)) {
        _fail('Неизвестная функция «$name»');
      }
      if (!_take('(')) _fail('После функции ожидается открывающая скобка');
      final argument = _sum();
      if (!_take(')')) _fail('Ожидается закрывающая скобка');
      return FunctionNode(name, argument);
    }
    final match = RegExp(
      r'(?:[0-9]+(?:[.,][0-9]*)?|[.,][0-9]+)(?:[eE][+-]?[0-9]+)?',
    ).matchAsPrefix(source, position);
    if (match == null) _fail('Ожидается число, функция или скобка');
    position = match.end;
    final value = double.tryParse(match[0]!.replaceAll(',', '.'));
    if (value == null || !value.isFinite) {
      _fail('Число вне допустимого диапазона');
    }
    return NumberNode(value);
  }
}
