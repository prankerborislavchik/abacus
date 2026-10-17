import 'package:abacus/calculator/domain/result_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatResult', () {
    test('целое без дробной части', () {
      expect(formatResult(14), '14');
    });

    test('0.1 + 0.2 отображается как 0.3', () {
      expect(formatResult(0.1 + 0.2), '0.3');
    });

    test('убирает завершающие нули', () {
      expect(formatResult(1.5), '1.5');
      expect(formatResult(2.0), '2');
    });

    test('ноль и минус-ноль дают "0"', () {
      expect(formatResult(0), '0');
      expect(formatResult(-0.0), '0');
    });

    test('не больше 12 значащих цифр', () {
      expect(formatResult(1 / 3), '0.333333333333');
    });

    test('большие числа — экспоненциальная запись', () {
      expect(formatResult(1e20), contains('e'));
    });
  });
}
