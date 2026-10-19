import 'package:flutter/material.dart';

import '../domain/calculator_memory.dart';
import '../domain/expression_evaluator.dart';
import '../domain/expression_node.dart';
import '../domain/expression_parser.dart';
import '../domain/result_formatter.dart';
import 'calculator_session_controller.dart';

import 'widgets/calculator_keypad.dart';
import 'widgets/calculator_notice.dart';
import 'widgets/expression_display.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    this.expression = '',
    this.result,
    this.session,
    this.notice,
  });

  /// Initial expression and feedback, useful when embedding the screen.
  final String expression;
  final String? result;

  /// External owners dispose their controller; otherwise the screen owns one.
  final CalculatorSessionController? session;
  final CalculatorNotice? notice;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final TextEditingController _expressionController;
  final _expressionFocus = FocusNode();
  late String _previousExpression;
  String? _result;
  CalculatorNotice? _notice;
  late CalculatorSessionController _session;
  double? _lastSessionResult;
  AngleMode _angleMode = AngleMode.deg;

  @override
  void initState() {
    super.initState();
    _previousExpression = widget.expression;
    _result = widget.result;
    _notice = widget.notice;
    _session = widget.session ?? CalculatorSessionController();
    _lastSessionResult = _session.currentResult;
    _session.addListener(_sessionChanged);
    _expressionController = TextEditingController(text: widget.expression)
      ..selection = TextSelection.collapsed(offset: widget.expression.length)
      ..addListener(_expressionChanged);
  }

  void _expressionChanged() {
    final expression = _expressionController.text;
    if (expression == _previousExpression) return;
    _previousExpression = expression;
    _session.invalidateResult();
    setState(() {
      _result = null;
      _notice = null;
    });
  }

  void _sessionChanged() {
    setState(() {
      if (_lastSessionResult != _session.currentResult) {
        _result = null;
        if (_session.currentResult != null) _notice = null;
      }
      _lastSessionResult = _session.currentResult;
    });
  }

  @override
  void didUpdateWidget(CalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _session.removeListener(_sessionChanged);
      if (oldWidget.session == null) _session.dispose();
      _session = widget.session ?? CalculatorSessionController();
      _lastSessionResult = _session.currentResult;
      _session.addListener(_sessionChanged);
      _result = null;
      _notice = null;
    }
  }

  void _addToMemory() {
    try {
      _session.addToMemory();
    } on MemoryException catch (error) {
      setState(() => _notice = CalculatorNotice(message: error.message));
      _expressionFocus.requestFocus();
      return;
    }
    setState(() => _notice = null);
    _expressionFocus.requestFocus();
  }

  void _clearMemory() {
    _session.clearMemory();
    setState(() => _notice = null);
    _expressionFocus.requestFocus();
  }

  void _recallMemory() {
    final text = _session.recallExpression();
    if (text == null) return;
    _session.invalidateResult();
    setState(() {
      _result = null;
      _notice = null;
    });
    _insertText(text);
  }

  void _clearExpression() {
    _session.invalidateResult();
    _expressionController.clear();
    setState(() {
      _result = null;
      _notice = null;
    });
    _expressionFocus.requestFocus();
  }

  TextSelection get _selection {
    final value = _expressionController.value;
    return value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
  }

  // Expression buttons and memory recall share cursor/selection handling.
  void _insertText(String text) {
    final selection = _selection;
    _replaceRange(selection.start, selection.end, text);
  }

  void _deleteBackward() {
    final selection = _selection;
    var start = selection.start;
    if (selection.isCollapsed && start > 0) {
      final prefix = _expressionController.text.substring(0, start);
      start -= prefix.characters.last.length;
    }
    _replaceRange(start, selection.end, '');
  }

  void _replaceRange(int start, int end, String text) {
    _expressionController.value = TextEditingValue(
      text: _expressionController.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    _expressionFocus.requestFocus();
  }

  void _submitExpression() {
    _session.invalidateResult();
    try {
      final expression = const ExpressionParser().parse(
        _expressionController.text,
      );
      setState(() {
        _result = null;
        _notice = null;
      });
      _session.publishResult(evaluate(expression, angleMode: _angleMode));
    } on ParseException catch (error) {
      _showCalculationError(error.message);
    } on EvaluationException catch (error) {
      _showCalculationError(error.message);
    }
    _expressionFocus.requestFocus();
  }

  void _showCalculationError(String message) {
    setState(() {
      _result = null;
      _notice = CalculatorNotice(message: message);
    });
  }

  void _changeAngleMode(Set<AngleMode> selection) {
    final mode = selection.single;
    if (mode == _angleMode) return;
    _session.invalidateResult();
    setState(() {
      _angleMode = mode;
      _result = null;
      _notice = null;
    });
    _expressionFocus.requestFocus();
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    if (widget.session == null) _session.dispose();
    _expressionController.dispose();
    _expressionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEFFFC),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFE0E5DA)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0926392C),
                              blurRadius: 32,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Header(
                                memory: _session.memoryValue == null
                                    ? null
                                    : formatResult(_session.memoryValue!),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  const Text(
                                    'Углы',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF65765E),
                                    ),
                                  ),
                                  SegmentedButton<AngleMode>(
                                    segments: const [
                                      ButtonSegment(
                                        value: AngleMode.deg,
                                        label: Text('DEG'),
                                        tooltip: 'Градусы',
                                      ),
                                      ButtonSegment(
                                        value: AngleMode.rad,
                                        label: Text('RAD'),
                                        tooltip: 'Радианы',
                                      ),
                                    ],
                                    selected: {_angleMode},
                                    showSelectedIcon: false,
                                    onSelectionChanged: _changeAngleMode,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ExpressionDisplay(
                                controller: _expressionController,
                                focusNode: _expressionFocus,
                                result: _session.currentResult == null
                                    ? _result
                                    : formatResult(_session.currentResult!),
                                onSubmitted: _submitExpression,
                              ),
                              if (_notice case final message?) ...[
                                const SizedBox(height: 12),
                                message,
                              ],
                              const SizedBox(height: 20),
                              CalculatorKeypad(
                                onInsert: _insertText,
                                onBackspace: _deleteBackward,
                                onMemoryAdd: _session.currentResult == null
                                    ? null
                                    : _addToMemory,
                                onMemoryRecall: _session.memoryValue == null
                                    ? null
                                    : _recallMemory,
                                onMemoryClear: _clearMemory,
                                onClear: _clearExpression,
                                onCalculate: _submitExpression,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.memory});

  final String? memory;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        const Text(
          'Abacus',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              'Память  ${memory ?? '—'}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF50634D)),
            ),
          ),
        ),
      ],
    );
  }
}
