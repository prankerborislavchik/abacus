import 'package:abacus/calculator/domain/expression_evaluator.dart';
import 'package:abacus/calculator/domain/expression_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('long flat AST reports complexity instead of overflowing the stack', () {
    ExpressionNode expression = const NumberNode(1);
    for (var i = 1; i < 20000; i++) {
      expression = BinaryOpNode('+', expression, const NumberNode(1));
    }
    expect(
      () => evaluate(expression),
      throwsA(
        isA<EvaluationException>().having(
          (error) => error.message,
          'message',
          'Слишком сложное выражение',
        ),
      ),
    );
    expect(evaluate(const NumberNode(3)), 3);
  });

  test('moderately deep flat AST still evaluates', () {
    ExpressionNode expression = const NumberNode(1);
    for (var i = 1; i < 300; i++) {
      expression = BinaryOpNode('+', expression, const NumberNode(1));
    }
    expect(evaluate(expression), 300);
  });

  group('evaluate: бинарные операции', () {
    test('складывает и умножает с учётом дерева: 2+3*4 = 14', () {
      final ast = BinaryOpNode(
        '+',
        NumberNode(2),
        BinaryOpNode('*', NumberNode(3), NumberNode(4)),
      );
      expect(evaluate(ast), 14);
    });

    test('остаток со знаком делимого: -7 % 3 = -1', () {
      final ast = BinaryOpNode(
        '%',
        UnaryOpNode('-', NumberNode(7)),
        NumberNode(3),
      );
      expect(evaluate(ast), -1);
    });

    test('степень: 2^10 = 1024', () {
      final ast = BinaryOpNode('^', NumberNode(2), NumberNode(10));
      expect(evaluate(ast), 1024);
    });

    test('правоассоциативная степень из дерева: 2^(3^2) = 512', () {
      final ast = BinaryOpNode(
        '^',
        NumberNode(2),
        BinaryOpNode('^', NumberNode(3), NumberNode(2)),
      );
      expect(evaluate(ast), 512);
    });
  });

  group('evaluate: унарный минус', () {
    test('-(2^2) = -4 — приоритет степени уже задан деревом', () {
      final ast = UnaryOpNode(
        '-',
        BinaryOpNode('^', NumberNode(2), NumberNode(2)),
      );
      expect(evaluate(ast), -4);
    });
  });

  group('evaluate: функции и режим углов', () {
    test('sin(90) в DEG = 1', () {
      final ast = FunctionNode('sin', NumberNode(90));
      expect(evaluate(ast, angleMode: AngleMode.deg), closeTo(1, 1e-12));
    });

    test('sin(90) в RAD — не 1', () {
      final ast = FunctionNode('sin', NumberNode(90));
      expect(
        evaluate(ast, angleMode: AngleMode.rad),
        closeTo(0.8939966636, 1e-10),
      );
    });

    test('cos(0) = 1 в обоих режимах', () {
      final ast = FunctionNode('cos', NumberNode(0));
      expect(evaluate(ast, angleMode: AngleMode.deg), 1);
      expect(evaluate(ast, angleMode: AngleMode.rad), 1);
    });

    test('sqrt, floor, ceil работают без перевода углов', () {
      expect(evaluate(FunctionNode('sqrt', NumberNode(9))), 3);
      expect(evaluate(FunctionNode('floor', NumberNode(2.7))), 2);
      expect(evaluate(FunctionNode('ceil', NumberNode(2.1))), 3);
    });
  });

  group('evaluate: математические ошибки', () {
    test('деление на ноль', () {
      final ast = BinaryOpNode('/', NumberNode(1), NumberNode(0));
      expect(() => evaluate(ast), throwsA(isA<EvaluationException>()));
    });

    test('остаток от деления на ноль', () {
      final ast = BinaryOpNode('%', NumberNode(1), NumberNode(0));
      expect(() => evaluate(ast), throwsA(isA<EvaluationException>()));
    });

    test('sqrt отрицательного', () {
      final ast = FunctionNode('sqrt', UnaryOpNode('-', NumberNode(1)));
      expect(() => evaluate(ast), throwsA(isA<EvaluationException>()));
    });

    test('переполнение: 1e308 * 1e308', () {
      final ast = BinaryOpNode('*', NumberNode(1e308), NumberNode(1e308));
      expect(() => evaluate(ast), throwsA(isA<EvaluationException>()));
    });

    test('переполнение в дочернем узле: 1/(10^400)', () {
      // 10^400 само по себе переполняется; деление не должно скрывать это.
      final ast = BinaryOpNode(
        '/',
        NumberNode(1),
        BinaryOpNode('^', NumberNode(10), NumberNode(400)),
      );
      expect(() => evaluate(ast), throwsA(isA<EvaluationException>()));
    });

    test('NaN в дочернем узле: ((-1)^0.5)^0', () {
      // (-1)^0.5 даёт NaN; внешняя степень не должна превращать это в 1.0.
      final inner = BinaryOpNode(
        '^',
        UnaryOpNode('-', NumberNode(1)),
        NumberNode(0.5),
      );
      final ast = BinaryOpNode('^', inner, NumberNode(0));
      expect(() => evaluate(ast), throwsA(isA<EvaluationException>()));
    });
  });

  group('evaluate: большие конечные углы в DEG', () {
    // Регрессия: arg * pi / 180 переполнялся для конечного arg,
    // потому что умножение на pi выполнялось до деления на 180.
    test('sin(1e308) в DEG возвращает конечное число', () {
      final ast = FunctionNode('sin', NumberNode(1e308));
      final result = evaluate(ast, angleMode: AngleMode.deg);
      expect(result.isFinite, isTrue);
      expect(result.abs(), lessThanOrEqualTo(1));
    });

    test('cos(1e308) в DEG возвращает конечное число', () {
      final ast = FunctionNode('cos', NumberNode(1e308));
      final result = evaluate(ast, angleMode: AngleMode.deg);
      expect(result.isFinite, isTrue);
      expect(result.abs(), lessThanOrEqualTo(1));
    });
  });
}
