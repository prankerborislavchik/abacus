import 'dart:ui';

import 'package:abacus/calculator/presentation/calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final desktopPlatforms = TargetPlatformVariant({
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  });

  Future<TestGesture> showCalculator(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: CalculatorScreen()));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    return mouse;
  }

  Future<void> clickKey(
    WidgetTester tester,
    TestGesture mouse,
    String label,
  ) async {
    final position = tester.getCenter(find.widgetWithText(FilledButton, label));
    await mouse.moveTo(position);
    await mouse.down(position);
    await tester.pump();
    await mouse.up();
    await tester.pumpAndSettle();
  }

  String expression(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets(
    'successive mouse clicks append digits instead of replacing the expression',
    (tester) async {
      final mouse = await showCalculator(tester);
      await clickKey(tester, mouse, '1');
      await clickKey(tester, mouse, '2');
      expect(expression(tester), '12');
    },
    variant: desktopPlatforms,
  );

  testWidgets(
    'mouse insertion replaces only the selected fragment then continues there',
    (tester) async {
      final mouse = await showCalculator(tester);
      await tester.enterText(find.byType(TextField), '12+34');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      await clickKey(tester, mouse, 'sin');
      await clickKey(tester, mouse, '9');
      expect(expression(tester), '12+sin(9');
    },
    variant: desktopPlatforms,
  );

  testWidgets('successive mouse backspaces remove one character each', (
    tester,
  ) async {
    final mouse = await showCalculator(tester);
    await tester.enterText(find.byType(TextField), '123');
    await clickKey(tester, mouse, '⌫');
    await clickKey(tester, mouse, '⌫');
    expect(expression(tester), '1');
  }, variant: desktopPlatforms);
}
