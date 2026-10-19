import 'package:abacus/calculator/domain/expression_node.dart';
import 'package:abacus/calculator/presentation/calculator_screen.dart';
import 'package:abacus/calculator/presentation/widgets/calculator_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final enter in [false, true]) {
    testWidgets('validation via ${enter ? 'Enter' : '='} and editing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final received = <ExpressionNode>[];
      await tester.pumpWidget(
        MaterialApp(home: CalculatorScreen(onCalculate: received.add)),
      );
      final field = find.byType(TextField);
      await tester.enterText(field, '2+*3');
      expect(find.byType(CalculatorNotice), findsNothing);
      Future<void> submit() async {
        if (enter) {
          await tester.testTextInput.receiveAction(TextInputAction.done);
        } else {
          await tester.tap(find.widgetWithText(FilledButton, '='));
        }
        await tester.pumpAndSettle();
      }

      await submit();
      expect(find.byType(CalculatorNotice), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, '2+*3');
      expect(received, isEmpty);
      await tester.enterText(field, '2+3*4');
      await tester.pump();
      expect(find.byType(CalculatorNotice), findsNothing);
      await submit();
      expect(received.single, isA<BinaryOpNode>());
      expect(find.byType(CalculatorNotice), findsNothing);
      expect(find.text('14'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('deep nesting shows a parse error and keeps the expression', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final received = <ExpressionNode>[];
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(onCalculate: received.add)),
    );
    final field = find.byType(TextField);
    final expression = '(' * 5000;
    await tester.enterText(field, expression);

    await tester.tap(find.widgetWithText(FilledButton, '='));
    await tester.pumpAndSettle();

    expect(find.byType(CalculatorNotice), findsOneWidget);
    expect(find.textContaining('Слишком глубокая вложенность'), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, expression);
    expect(received, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
