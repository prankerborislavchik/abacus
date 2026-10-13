import 'package:flutter/material.dart';

import 'widgets/calculator_keypad.dart';
import 'widgets/calculator_notice.dart';
import 'widgets/expression_display.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    this.expression = '',
    this.result,
    this.memory,
    this.notice,
    this.onCalculate,
  });

  /// Initial expression and feedback, useful when embedding the screen.
  final String expression;
  final String? result;
  final String? memory;
  final CalculatorNotice? notice;

  /// Both Enter and `=` submit the current expression through this callback.
  /// Calculation stays unavailable until an implementation is connected.
  final ValueChanged<String>? onCalculate;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final TextEditingController _expressionController;
  final _expressionFocus = FocusNode();
  late String _previousExpression;
  String? _result;
  CalculatorNotice? _notice;

  @override
  void initState() {
    super.initState();
    _previousExpression = widget.expression;
    _result = widget.result;
    _notice = widget.notice;
    _expressionController = TextEditingController(text: widget.expression)
      ..selection = TextSelection.collapsed(offset: widget.expression.length)
      ..addListener(_expressionChanged);
  }

  void _expressionChanged() {
    final expression = _expressionController.text;
    if (expression == _previousExpression) return;
    _previousExpression = expression;
    setState(() {
      _result = null;
      _notice = null;
    });
  }

  TextSelection get _selection {
    final value = _expressionController.value;
    return value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
  }

  // Also used by future memory recall: callers supply the insertion text.
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
    widget.onCalculate?.call(_expressionController.text);
    _expressionFocus.requestFocus();
  }

  @override
  void dispose() {
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
                              _Header(memory: widget.memory),
                              const SizedBox(height: 24),
                              ExpressionDisplay(
                                controller: _expressionController,
                                focusNode: _expressionFocus,
                                result: _result,
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
                                onCalculate: widget.onCalculate == null
                                    ? null
                                    : _submitExpression,
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
