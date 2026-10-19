import 'package:abacus/calculator/domain/calculator_memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'empty memory has no recall and missing result does not create a value',
    () {
      final memory = CalculatorMemory();
      memory.add(null);
      expect(memory.value, isNull);
      expect(memory.recallExpression(), isNull);
    },
  );

  test('accumulation, repeated recall and clear', () {
    final memory = CalculatorMemory();
    memory.add(5);
    memory.add(3);
    expect(memory.value, 8);
    expect(memory.recallExpression(), '8.0');
    expect(memory.recallExpression(), '8.0');
    expect(memory.value, 8);
    memory.clear();
    memory.clear();
    expect(memory.value, isNull);
    expect(memory.recallExpression(), isNull);
    memory.add(2);
    expect(memory.value, 2);
  });

  test('negative recall is parenthesized and preserves full precision', () {
    final memory = CalculatorMemory();
    memory.add(-1.2345678901234567);
    final text = memory.recallExpression()!;
    expect(text, startsWith('('));
    expect(text, endsWith(')'));
    expect(double.parse(text.substring(1, text.length - 1)), memory.value);
  });

  test('zero is a stored value, new sessions have independent memory', () {
    final first = CalculatorMemory()..add(-0.0);
    final second = CalculatorMemory();
    expect(first.value, 0);
    expect(first.recallExpression(), '0');
    expect(second.value, isNull);
    second.add(7);
    first.clear();
    expect(second.value, 7);
  });

  test('missing or nonfinite results cannot corrupt accumulated memory', () {
    final memory = CalculatorMemory()..add(3);
    memory.add(null);
    for (final result in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(() => memory.add(result), throwsA(isA<MemoryException>()));
      expect(memory.value, 3);
    }
  });

  test('overflow is atomic and a subsequent valid addition still works', () {
    final memory = CalculatorMemory()..add(1e308);
    expect(() => memory.add(1e308), throwsA(isA<MemoryException>()));
    expect(memory.value, 1e308);
    memory.add(-1e308);
    expect(memory.value, 0);
  });

  test(
    'small and large recalled numbers round trip without display rounding',
    () {
      for (final value in [1e-200, 1e200, 0.1 + 0.2]) {
        final memory = CalculatorMemory()..add(value);
        expect(double.parse(memory.recallExpression()!), value);
        expect(memory.value, value);
      }
    },
  );
}
