import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:abacus/calculator/presentation/calculator_screen.dart';
import 'package:abacus/calculator/presentation/widgets/calculator_notice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Completer<Object?>? pendingClipboardRead;
  setUp(() {
    pendingClipboardRead = null;
    var clipboard = <String, dynamic>{'text': ''};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              clipboard = Map<String, dynamic>.from(call.arguments as Map);
              return null;
            case 'Clipboard.getData':
              return pendingClipboardRead == null
                  ? clipboard
                  : pendingClipboardRead!.future;
            case 'Clipboard.hasStrings':
              return {'value': (clipboard['text'] as String).isNotEmpty};
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  final platforms = TargetPlatformVariant({
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  });
  const selection = TextSelection(baseOffset: 1, extentOffset: 4);
  const notice = 'Прежняя ошибка проверки';

  Future<TextEditingController> showCalculator(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: CalculatorScreen(
          expression: '12+34',
          result: '99',
          notice: CalculatorNotice(message: notice),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    await tester.tap(find.byType(TextField));
    controller.selection = selection;
    await tester.pump();
    return controller;
  }

  void expectUnchanged(TextEditingController controller) {
    expect(controller.text, '12+34');
    expect(controller.selection, selection);
    expect(find.text('99'), findsOneWidget);
    expect(find.text(notice), findsOneWidget);
  }

  Future<void> pasteShortcut(WidgetTester tester, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    final modifier = defaultTargetPlatform == TargetPlatform.macOS
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(modifier);
    await tester.pumpAndSettle();
  }

  testWidgets('forbidden typing preserves selection and previous feedback', (
    tester,
  ) async {
    final controller = await showCalculator(tester);
    for (final character in ['ж', '😀', '\t', '\u00a0', '×', '÷', '−']) {
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: '1${character}4',
          selection: TextSelection.collapsed(offset: 1 + character.length),
        ),
      );
      await tester.pump();
      expectUnchanged(controller);
    }
  }, variant: platforms);

  testWidgets('allowed alphabet is preserved without checking syntax or case', (
    tester,
  ) async {
    await showCalculator(tester);
    const text =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
        '+-*/%^()., sin( 2+*3 sincos(2) aboba(2)';
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      text,
    );
    expect(find.text('99'), findsNothing);
    expect(find.text(notice), findsNothing);
  }, variant: platforms);

  testWidgets('mixed clipboard rejects whole paste including line breaks', (
    tester,
  ) async {
    final controller = await showCalculator(tester);
    for (final text in [
      '12ж3',
      '12\n3',
      '12\r\n3',
      '12\t3',
      '12😀3',
      '1\u00a02',
    ]) {
      await pasteShortcut(tester, text);
      expectUnchanged(controller);
      expect(find.textContaining('Не удалось вставить:'), findsOneWidget);
    }
  }, variant: platforms);

  testWidgets('allowed clipboard replaces selection and clears old feedback', (
    tester,
  ) async {
    final controller = await showCalculator(tester);
    await pasteShortcut(tester, 'Arcsin(2) + aboba(');
    expect(controller.text, '1Arcsin(2) + aboba(4');
    expect(controller.selection, const TextSelection.collapsed(offset: 19));
    expect(find.text('99'), findsNothing);
    expect(find.text(notice), findsNothing);
  }, variant: platforms);

  testWidgets('context menu paste uses the same atomic rejection', (
    tester,
  ) async {
    final controller = await showCalculator(tester);
    await Clipboard.setData(const ClipboardData(text: '12\n3'));
    final editable = tester.state<EditableTextState>(
      find.descendant(
        of: find.byType(TextField),
        matching: find.byType(EditableText),
      ),
    );
    editable.showToolbar();
    await tester.pumpAndSettle();
    final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
      find.byType(AdaptiveTextSelectionToolbar),
    );
    toolbar.buttonItems!
        .singleWhere((item) => item.type == ContextMenuButtonType.paste)
        .onPressed!();
    await tester.pumpAndSettle();
    expectUnchanged(controller);
    expect(find.textContaining('Не удалось вставить:'), findsOneWidget);
  }, variant: platforms);

  for (final forbidden in [false, true]) {
    testWidgets('delayed context menu paste: forbidden=$forbidden', (
      tester,
    ) async {
      final controller = await showCalculator(tester);
      await Clipboard.setData(const ClipboardData(text: '7'));
      final field = tester.widget<TextField>(find.byType(TextField));
      final editable = tester.state<EditableTextState>(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byType(EditableText),
        ),
      );
      editable.showToolbar();
      await tester.pumpAndSettle();
      final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
        find.byType(AdaptiveTextSelectionToolbar),
      );
      pendingClipboardRead = Completer<Object?>();
      toolbar.buttonItems!
          .singleWhere((item) => item.type == ContextMenuButtonType.paste)
          .onPressed!();
      // Remove the menu before the platform returns the clipboard contents.
      await tester.pump();
      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      expect(field.focusNode!.hasFocus, isTrue);
      pendingClipboardRead!.complete({'text': forbidden ? '12ж3' : '7'});
      await tester.pumpAndSettle();
      if (forbidden) {
        expectUnchanged(controller);
        expect(find.textContaining('Не удалось вставить:'), findsOneWidget);
      } else {
        expect(controller.text, '174');
        expect(controller.selection, const TextSelection.collapsed(offset: 2));
        expect(find.text('99'), findsNothing);
        expect(find.text(notice), findsNothing);
      }
    }, variant: platforms);
  }

  testWidgets('accessibility paste also rejects the original clipboard', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = await showCalculator(tester);
    await Clipboard.setData(const ClipboardData(text: '12\n3'));
    final node = tester.getSemantics(find.byType(TextField));
    node.owner!.performAction(node.id, SemanticsAction.paste);
    await tester.pumpAndSettle();
    expectUnchanged(controller);
    expect(find.textContaining('Не удалось вставить:'), findsOneWidget);
    semantics.dispose();
  }, variant: platforms);
}
