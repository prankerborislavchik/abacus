import 'package:abacus/calculator/domain/expression_evaluator.dart';
import 'package:abacus/calculator/domain/expression_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  });
}
