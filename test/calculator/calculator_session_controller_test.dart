import 'package:abacus/calculator/domain/calculator_memory.dart';
import 'package:abacus/calculator/presentation/calculator_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('result invalidation preserves memory and prevents stale M+', () {
    final session = CalculatorSessionController();
    addTearDown(session.dispose);
    session.publishResult(5);
    session.addToMemory();
    session.invalidateResult();
    session.addToMemory();
    expect(session.currentResult, isNull);
    expect(session.memoryValue, 5);
    session.publishResult(3);
    session.addToMemory();
    expect(session.memoryValue, 8);
    session.clearMemory();
    expect(session.memoryValue, isNull);
    expect(session.currentResult, 3);
  });

  test('invalid publication clears old result without corrupting memory', () {
    final session = CalculatorSessionController();
    addTearDown(session.dispose);
    session.publishResult(7);
    session.addToMemory();
    expect(() => session.publishResult(double.nan), throwsArgumentError);
    expect(session.currentResult, isNull);
    expect(session.memoryValue, 7);
  });

  test('overflow preserves result and memory', () {
    final session = CalculatorSessionController();
    addTearDown(session.dispose);
    session.publishResult(1e308);
    session.addToMemory();
    expect(session.addToMemory, throwsA(isA<MemoryException>()));
    expect(session.currentResult, 1e308);
    expect(session.memoryValue, 1e308);
  });
}
