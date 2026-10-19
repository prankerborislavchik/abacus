import 'package:abacus/app.dart';
import 'package:abacus/calculator/domain/expression_node.dart';
import 'package:abacus/calculator/presentation/calculator_screen.dart';
import 'package:abacus/calculator/presentation/calculator_session_controller.dart';
import 'package:abacus/calculator/presentation/widgets/calculator_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void sizeScreen(WidgetTester tester, {Size size = const Size(400, 1000)}) {
  tester.view.physicalSize = size;
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

String? result(WidgetTester tester) =>
    tester.widget<SelectableText>(find.byType(SelectableText)).data;

bool enabled(WidgetTester tester, String label) =>
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, label))
        .onPressed !=
    null;

Future<void> changeMode(WidgetTester tester, String label) async {
  final segment = find.text(label);
  await tester.ensureVisible(segment);
  await tester.tap(segment);
  await tester.pumpAndSettle();
}

void main() {
  for (final enter in [false, true]) {
    testWidgets(
      'default app calculates through ${enter ? 'Enter' : '='} and keeps editing',
      (tester) async {
        sizeScreen(tester);
        await tester.pumpWidget(const AbacusApp());
        final field = find.byType(TextField);
        Future<void> submit() async {
          if (enter) {
            await tester.testTextInput.receiveAction(TextInputAction.done);
            await tester.pumpAndSettle();
          } else {
            await click(tester, '=');
          }
        }

        for (final entry in {
          '2+3*4': '14',
          '2^3^2': '512',
          '-2^2': '-4',
          '1,5+2.5': '4',
          '-5%3': '-2',
          'floor(-2.7)+ceil(-2.7)': '-5',
          'sqrt(9)': '3',
          '0.1+0.2': '0.3',
        }.entries) {
          await tester.enterText(field, entry.key);
          await tester.pump();
          expect(result(tester), '—');
          expect(enabled(tester, 'M+'), isFalse);
          await submit();
          expect(result(tester), entry.value);
          expect(enabled(tester, 'M+'), isTrue);
          expect(tester.widget<TextField>(field).controller!.text, entry.key);
          await submit();
          expect(result(tester), entry.value);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'DEG/RAD invalidates the result, preserves memory and returns focus',
    (tester) async {
      sizeScreen(tester);
      final session = CalculatorSessionController();
      addTearDown(session.dispose);
      await tester.pumpWidget(
        AbacusApp(home: CalculatorScreen(session: session)),
      );
      final field = find.byType(TextField);
      expect(
        tester
            .widget<SegmentedButton<AngleMode>>(
              find.byType(SegmentedButton<AngleMode>),
            )
            .selected,
        {AngleMode.deg},
      );
      await tester.enterText(field, 'sin(90)');
      await click(tester, '=');
      expect(session.currentResult, closeTo(1, 1e-12));
      await click(tester, 'M+');
      await changeMode(tester, 'RAD');
      expect(result(tester), '—');
      expect(session.currentResult, isNull);
      expect(session.memoryValue, closeTo(1, 1e-12));
      expect(enabled(tester, 'M+'), isFalse);
      expect(tester.widget<TextField>(field).controller!.text, 'sin(90)');
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      await click(tester, '=');
      expect(session.currentResult, closeTo(0.8939966636005579, 1e-12));
      await tester.enterText(field, 'sin(1.5707963267948966)');
      await click(tester, '=');
      expect(session.currentResult, closeTo(1, 1e-12));
      await changeMode(tester, 'DEG');
      expect(result(tester), '—');
      await tester.enterText(field, 'cos(0)');
      await click(tester, '=');
      expect(session.currentResult, 1);
      await changeMode(tester, 'RAD');
      await click(tester, '=');
      expect(session.currentResult, 1);
      expect(session.memoryValue, closeTo(1, 1e-12));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mathematical errors hide stale results and preserve expression and memory',
    (tester) async {
      sizeScreen(tester);
      final session = CalculatorSessionController()
        ..publishResult(8)
        ..addToMemory();
      addTearDown(session.dispose);
      await tester.pumpWidget(
        AbacusApp(home: CalculatorScreen(session: session)),
      );
      final field = find.byType(TextField);
      for (final entry in {
        '1/0': 'Деление на ноль',
        '5%0': 'Остаток от деления на ноль',
        'sqrt(-1)': 'Корень из отрицательного числа',
        '10^400': 'Результат не является конечным числом',
        '(-1)^0.5': 'Результат не является конечным числом',
        List.filled(20000, '1').join('+'): 'Слишком сложное выражение',
      }.entries) {
        await tester.enterText(field, entry.key);
        // Seed a stale result after editing to verify the submission itself clears it.
        session.publishResult(99);
        await tester.pump();
        await click(tester, '=');
        expect(find.text(entry.value), findsOneWidget);
        expect(session.currentResult, isNull);
        expect(result(tester), '—');
        expect(enabled(tester, 'M+'), isFalse);
        expect(tester.widget<TextField>(field).controller!.text, entry.key);
        expect(session.memoryValue, 8);
        expect(tester.takeException(), isNull);
        await tester.enterText(field, '2+3');
        await tester.pump();
        expect(find.byType(CalculatorNotice), findsNothing);
        await click(tester, '=');
        expect(result(tester), '5');
      }
      await tester.enterText(field, '1/0');
      await click(tester, '=');
      await changeMode(tester, 'RAD');
      expect(find.byType(CalculatorNotice), findsNothing);
      expect(session.memoryValue, 8);
      expect(result(tester), '—');
    },
  );

  testWidgets(
    'real calculation supports the full memory flow in a narrow window',
    (tester) async {
      sizeScreen(tester, size: const Size(360, 760));
      await tester.pumpWidget(const AbacusApp());
      final field = find.byType(TextField);
      for (final value in ['5', '3']) {
        await tester.enterText(field, value);
        await click(tester, '=');
        await click(tester, 'M+');
        await click(tester, 'AC');
      }
      expect(find.text('Память  8'), findsOneWidget);
      await click(tester, 'MR');
      expect(tester.widget<TextField>(field).controller!.text, '8.0');
      await click(tester, '=');
      expect(result(tester), '8');
      await click(tester, 'MC');
      expect(result(tester), '8');
      expect(tester.widget<TextField>(field).controller!.text, '8.0');
      expect(enabled(tester, 'MR'), isFalse);
      await changeMode(tester, 'RAD');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text, '8.');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('display rounding does not reduce memory precision', (
    tester,
  ) async {
    sizeScreen(tester);
    final session = CalculatorSessionController();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      AbacusApp(home: CalculatorScreen(session: session)),
    );
    await tester.enterText(find.byType(TextField), '1/3');
    await click(tester, '=');
    expect(result(tester), '0.333333333333');
    expect(session.currentResult, 1 / 3);
    await click(tester, 'M+');
    await click(tester, 'AC');
    await click(tester, 'MR');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      (1 / 3).toString(),
    );
    await click(tester, '=');
    expect(session.currentResult, 1 / 3);
    expect(session.memoryValue, 1 / 3);
  });
}
