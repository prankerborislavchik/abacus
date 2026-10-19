import 'dart:ui';

import 'package:abacus/calculator/presentation/calculator_screen.dart';
import 'package:abacus/calculator/presentation/calculator_session_controller.dart';
import 'package:abacus/calculator/presentation/widgets/calculator_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('memory commands preserve independent state and selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = CalculatorSessionController();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(session: session)),
    );
    final field = find.byType(TextField);
    final controller = tester.widget<TextField>(field).controller!;
    Future<void> click(String label) async {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    bool enabled(String label) =>
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, label))
            .onPressed !=
        null;

    expect(enabled('M+'), isFalse);
    expect(enabled('MR'), isFalse);
    await tester.enterText(field, '5');
    session.publishResult(5); // Contract input from future #5 integration.
    await tester.pump();
    await click('M+');
    await tester.enterText(field, '3');
    await tester.pump();
    expect(enabled('M+'), isFalse);
    session.publishResult(3);
    await tester.pump();
    await click('M+');
    expect(session.memoryValue, 8);
    await click('AC');
    expect(controller.text, isEmpty);
    expect(session.currentResult, isNull);
    expect(session.memoryValue, 8);
    await click('MR');
    expect(controller.text, '8.0');
    expect(session.memoryValue, 8);
    session.publishResult(8);
    await tester.pump();
    await click('MC');
    expect(controller.text, '8.0');
    expect(session.currentResult, 8);
    expect(session.memoryValue, isNull);
    expect(enabled('MR'), isFalse);

    session.publishResult(-2.5);
    await tester.pump();
    await click('M+');
    await tester.enterText(field, '12+34');
    controller.selection = const TextSelection(baseOffset: 3, extentOffset: 5);
    await tester.pump();
    await click('MR');
    expect(controller.text, '12+(-2.5)');
    expect(controller.selection.baseOffset, 9);
    expect(session.currentResult, isNull);
    expect(session.memoryValue, -2.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'MC returns focus so keyboard editing continues',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = CalculatorSessionController()
        ..publishResult(5)
        ..addToMemory();
      addTearDown(session.dispose);
      await tester.pumpWidget(
        MaterialApp(home: CalculatorScreen(session: session)),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      await tester.enterText(field, '12');

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      final button = find.widgetWithText(FilledButton, 'MC');
      await tester.ensureVisible(button);
      final position = tester.getCenter(button);
      await mouse.moveTo(position);
      await mouse.down(position);
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(tester.widget<TextField>(field).controller!.text, '1');
      expect(session.memoryValue, isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    }),
  );

  testWidgets('MC clears a stale overflow notice before the next M+', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = CalculatorSessionController()
      ..publishResult(1e308)
      ..addToMemory();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(session: session)),
    );
    Future<void> click(String label) async {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await click('M+');
    expect(find.byType(CalculatorNotice), findsOneWidget);

    await click('MC');
    expect(find.byType(CalculatorNotice), findsNothing);
    expect(session.memoryValue, isNull);
    expect(session.currentResult, 1e308);

    await click('M+');
    expect(find.byType(CalculatorNotice), findsNothing);
    expect(session.memoryValue, 1e308);
  });

  testWidgets('successful M+ clears an earlier overflow notice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = CalculatorSessionController()
      ..publishResult(1e308)
      ..addToMemory();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(session: session)),
    );
    Future<void> click(String label) async {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await click('M+');
    expect(find.byType(CalculatorNotice), findsOneWidget);

    // Another owner of the session clears memory without the screen handler,
    // so the overflow notice is still visible when the next M+ succeeds.
    session.clearMemory();
    await tester.pump();
    expect(find.byType(CalculatorNotice), findsOneWidget);

    await click('M+');
    expect(find.byType(CalculatorNotice), findsNothing);
    expect(session.memoryValue, 1e308);
  });

  testWidgets('AC clears diagnostics even when expression is already empty', (
    tester,
  ) async {
    final session = CalculatorSessionController()
      ..publishResult(5)
      ..addToMemory();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          session: session,
          notice: const CalculatorNotice(message: 'Ошибка'),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'AC'));
    await tester.pump();
    expect(find.byType(CalculatorNotice), findsNothing);
    expect(session.currentResult, isNull);
    expect(session.memoryValue, 5);
  });
}
