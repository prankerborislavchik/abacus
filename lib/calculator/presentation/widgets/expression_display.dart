import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpressionDisplay extends StatelessWidget {
  const ExpressionDisplay({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    this.result,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final String? result;

  static final _forbiddenCharacter = RegExp(r'[^0-9a-zA-Z+*/%^()., \-]');
  static final _alphabetFormatter = TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        _forbiddenCharacter.hasMatch(newValue.text) ? oldValue : newValue,
  );

  Future<void> _paste(BuildContext context, SelectionChangedCause cause) async {
    // Inspect the original clipboard before Flutter's single-line formatter
    // can strip newlines. Reject the entire paste, including over a selection.
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted || !focusNode.hasFocus || data?.text == null) return;
    final text = data!.text!;
    if (_forbiddenCharacter.hasMatch(text)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось вставить: текст содержит недопустимые символы.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      return;
    }
    final editingContext = focusNode.context;
    final value = controller.value;
    if (editingContext == null || !value.selection.isValid) return;
    Actions.invoke(
      editingContext,
      ReplaceTextIntent(
        value.copyWith(
          selection: TextSelection.collapsed(offset: value.selection.end),
        ),
        text,
        value.selection,
        cause,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E9DB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ВЫРАЖЕНИЕ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
                color: Color(0xFF65765E),
              ),
            ),
            Semantics(
              label: 'Выражение',
              onPaste: () => _paste(context, SelectionChangedCause.toolbar),
              child: Actions(
                actions: <Type, Action<Intent>>{
                  PasteTextIntent: CallbackAction<PasteTextIntent>(
                    onInvoke: (intent) {
                      _paste(context, intent.cause);
                      return null;
                    },
                  ),
                },
                child: TextField(
                  inputFormatters: [_alphabetFormatter],
                  // Paste must outlive the menu overlay while reading the clipboard.
                  contextMenuBuilder: (_, editable) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editable.contextMenuAnchors,
                      buttonItems: [
                        for (final item in editable.contextMenuButtonItems)
                          if (item.type == ContextMenuButtonType.paste)
                            ContextMenuButtonItem(
                              type: ContextMenuButtonType.paste,
                              onPressed: () {
                                _paste(context, SelectionChangedCause.toolbar);
                                editable.hideToolbar();
                              },
                            )
                          else
                            item,
                      ],
                    );
                  },
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  // Keypad clicks return focus here without selecting the whole
                  // expression for replacement.
                  selectAllOnFocus: false,
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  // Keep focus and selection on Enter. Both submit controls
                  // use the same calculation handler.
                  onEditingComplete: () {},
                  onSubmitted: (_) => onSubmitted(),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 36,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Color(0xFF6E7C66)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const Divider(height: 16, color: Color(0xFFDCE3D4)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Результат',
                  style: TextStyle(fontSize: 13, color: Color(0xFF65765E)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    result ?? '—',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
