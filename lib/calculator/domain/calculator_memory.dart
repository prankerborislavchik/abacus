/// Calculator memory lives only as long as its owning screen/session.
class CalculatorMemory {
  double? _value;

  double? get value => _value;

  /// A missing current result cannot be added. Failed additions are atomic.
  void add(double? currentResult) {
    if (currentResult == null) return;
    if (!currentResult.isFinite) {
      throw const MemoryException(
        'В память можно добавить только конечное число.',
      );
    }
    final next = (_value ?? 0) + currentResult;
    if (!next.isFinite) {
      throw const MemoryException('Переполнение памяти: значение не изменено.');
    }
    _value = next;
  }

  void clear() => _value = null;

  /// Round-trippable numeric text, not the rounded display representation.
  /// The caller inserts it with the shared expression-editing mechanism.
  String? recallExpression() {
    final value = _value;
    if (value == null) return null;
    if (value == 0) return '0';
    final text = value.toString();
    return value < 0 ? '($text)' : text;
  }
}

class MemoryException implements Exception {
  const MemoryException(this.message);

  final String message;

  @override
  String toString() => 'MemoryException: $message';
}
