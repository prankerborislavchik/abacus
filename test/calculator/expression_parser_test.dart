import 'package:abacus/calculator/domain/expression_node.dart';
import 'package:abacus/calculator/domain/expression_parser.dart';
import 'package:abacus/calculator/domain/expression_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ExpressionParser();

  test('AST preserves precedence and associativity', () {
    final sum = parser.parse('2+3*4') as BinaryOpNode;
    expect(sum.operator, '+');
    expect((sum.left as NumberNode).value, 2);
    expect((sum.right as BinaryOpNode).operator, '*');
    final power = parser.parse('2^3^2') as BinaryOpNode;
    expect(power.operator, '^');
    expect((power.right as BinaryOpNode).operator, '^');
    final negative = parser.parse('-2^2') as UnaryOpNode;
    expect((negative.operand as BinaryOpNode).operator, '^');
    final grouped = parser.parse('(-2)^2') as BinaryOpNode;
    expect(grouped.left, isA<UnaryOpNode>());
    final left = parser.parse('8/4*2') as BinaryOpNode;
    expect(left.operator, '*');
    expect((left.left as BinaryOpNode).operator, '/');
  });

  for (final entry in {
    '2+3*4': 14.0,
    '(2+3)*4': 20.0,
    '2^3^2': 512.0,
    '-2^2': -4.0,
    '(-2)^2': 4.0,
    '2^-2': 0.25,
    '1,5+2.5': 4.0,
    '-5%3': -2.0,
    '8/4*2': 4.0,
    '8-4-2': 2.0,
    'sqrt(4+5)': 3.0,
    'floor(-2.7)': -3.0,
    'ceil(-2.7)': -2.0,
    'sin(90)': 1.0,
    'cos(0)': 1.0,
    ' .5 + 5. ': 5.5,
    '1e-3+2E+2': 200.001,
    '--2': 2.0,
  }.entries) {
    test('shared evaluator accepts parsed ${entry.key}', () {
      expect(evaluate(parser.parse(entry.key)), closeTo(entry.value, 1e-10));
    });
  }

  for (final expression in [
    '',
    ' ',
    '2+*3',
    '2(3+4)',
    '(2',
    '2)',
    '()',
    'sin()',
    'aboba(2)',
    'sincos(2)',
    'SIN(2)',
    'sin 2',
    '1..2',
    '1,2.3',
    '1 2',
    '1e',
    '1e+',
    '.',
    '+2',
    '2**3',
    '2\n+3',
    '2\t+3',
    'ж',
    'π',
    '1e999',
    '2=2',
  ]) {
    test('rejects invalid expression $expression', () {
      expect(() => parser.parse(expression), throwsA(isA<ParseException>()));
      expect(parser.parse('3'), isA<NumberNode>());
    });
  }

  for (final expression in ['1/0', '5%0', 'sqrt(-1)']) {
    test('$expression is a mathematical error, not a syntax error', () {
      final ast = parser.parse(expression);
      expect(() => evaluate(ast), throwsA(isA<EvaluationException>()));
    });
  }
}
