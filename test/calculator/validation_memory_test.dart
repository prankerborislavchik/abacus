import 'package:abacus/calculator/domain/expression_evaluator.dart';
import 'package:abacus/calculator/domain/expression_node.dart';
import 'package:abacus/calculator/presentation/calculator_screen.dart';
import 'package:abacus/calculator/presentation/calculator_session_controller.dart';
import 'package:abacus/calculator/presentation/widgets/calculator_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void sizeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> click(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> submit(WidgetTester tester, bool enter) async {
  if (enter) {
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  } else {
    await click(tester, '=');
  }
}

bool enabled(WidgetTester tester, String label) =>
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, label))
        .onPressed !=
    null;

void main() {
  for (final enter in [false, true]) {
    testWidgets(
      'invalid submission via ${enter ? 'Enter' : '='} clears only the result',
      (tester) async {
        sizeScreen(tester);
        final session = CalculatorSessionController()
          ..publishResult(5)
          ..addToMemory()
          ..publishResult(77);
        addTearDown(session.dispose);
        final received = <ExpressionNode>[];
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              expression: '2+*3',
              result: '99',
              session: session,
              onCalculate: received.add,
            ),
          ),
        );
        expect(enabled(tester, 'M+'), isTrue);

        await submit(tester, enter);

        expect(session.currentResult, isNull);
        expect(session.memoryValue, 5);
        expect(enabled(tester, 'M+'), isFalse);
        expect(received, isEmpty);
        expect(find.byType(CalculatorNotice), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '2+*3',
        );
        expect(find.text('77'), findsNothing);
        expect(find.text('99'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'valid submission via ${enter ? 'Enter' : '='} preserves a newly published result',
      (tester) async {
        sizeScreen(tester);
        final session = CalculatorSessionController()
          ..publishResult(5)
          ..addToMemory()
          ..publishResult(77);
        addTearDown(session.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: CalculatorScreen(
              expression: '2+3*4',
              session: session,
              onCalculate: (expression) {
                expect(session.currentResult, isNull);
                session.publishResult(evaluate(expression));
              },
            ),
          ),
        );

        await submit(tester, enter);

        expect(session.currentResult, 14);
        expect(find.text('14'), findsOneWidget);
        expect(enabled(tester, 'M+'), isTrue);
        expect(session.memoryValue, 5);
        await click(tester, 'M+');
        expect(session.memoryValue, 19);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('validation works without a calculation callback', (
    tester,
  ) async {
    sizeScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: CalculatorScreen(expression: '2+*3', result: '99'),
      ),
    );
    expect(enabled(tester, '='), isTrue);
    await click(tester, '=');
    expect(find.byType(CalculatorNotice), findsOneWidget);
    expect(find.text('99'), findsNothing);
    await tester.enterText(find.byType(TextField), '2+3*4');
    await click(tester, '=');
    expect(find.byType(CalculatorNotice), findsNothing);
    expect(find.text('14'), findsNothing);
    expect(enabled(tester, 'M+'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('memory recall scientific notation uses the shared parser', (
    tester,
  ) async {
    sizeScreen(tester);
    final session = CalculatorSessionController()
      ..publishResult(1e-7)
      ..addToMemory();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          session: session,
          onCalculate: (expression) =>
              session.publishResult(evaluate(expression)),
        ),
      ),
    );
    await click(tester, 'AC');
    await click(tester, 'MR');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '1e-7',
    );
    await click(tester, '=');
    expect(session.currentResult, 1e-7);
    expect(session.memoryValue, 1e-7);
    expect(find.byType(CalculatorNotice), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
