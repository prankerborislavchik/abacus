import 'package:flutter/foundation.dart';

import '../domain/calculator_memory.dart';

/// Numeric result and memory for one screen. Expression editing stays in UI.
class CalculatorSessionController extends ChangeNotifier {
  final _memory = CalculatorMemory();
  double? _currentResult;

  double? get currentResult => _currentResult;
  double? get memoryValue => _memory.value;

  /// Called by the calculation integration only after successful evaluation.
  void publishResult(double value) {
    if (!value.isFinite) {
      invalidateResult();
      throw ArgumentError.value(value, 'value', 'Expected a finite result');
    }
    _currentResult = value;
    notifyListeners();
  }

  /// Editing, calculation errors, AC and angle-mode changes invalidate results.
  void invalidateResult() {
    if (_currentResult == null) return;
    _currentResult = null;
    notifyListeners();
  }

  void addToMemory() {
    if (_currentResult == null) return;
    _memory.add(_currentResult);
    notifyListeners();
  }

  String? recallExpression() => _memory.recallExpression();

  void clearMemory() {
    _memory.clear();
    notifyListeners();
  }
}
