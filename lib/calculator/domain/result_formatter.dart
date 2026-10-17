/// Форматирует результат для экрана: максимум 12 значащих цифр,
/// без завершающих нулей. 0.1 + 0.2 отображается как "0.3".
/// Внутреннее double-значение отсюда не берут — это только представление.
String formatResult(double value) {
  if (value == 0) return '0'; // убирает "-0"

  // toPrecision(12) сам решает, когда нужна экспоненциальная запись.
  var text = value.toStringAsPrecision(12);

  if (text.contains('e')) {
    // Приведём мантиссу вида "1.23000000000e+05" к "1.23e+05".
    final parts = text.split('e');
    text = '${_trimZeros(parts[0])}e${parts[1]}';
  } else {
    text = _trimZeros(text);
  }
  return text;
}

String _trimZeros(String s) {
  if (!s.contains('.')) return s;
  var r = s;
  while (r.endsWith('0')) {
    r = r.substring(0, r.length - 1);
  }
  if (r.endsWith('.')) r = r.substring(0, r.length - 1);
  return r;
}
