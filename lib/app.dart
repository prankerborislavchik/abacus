import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'calculator/presentation/calculator_screen.dart';

class AbacusApp extends StatelessWidget {
  const AbacusApp({super.key, this.home = const CalculatorScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF405B45),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Abacus',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: colors,
        scaffoldBackgroundColor: const Color(0xFFF2F3EE),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF26392C),
          displayColor: const Color(0xFF26392C),
        ),
        tooltipTheme: const TooltipThemeData(
          waitDuration: Duration(milliseconds: 600),
        ),
      ),
      home: home,
    );
  }
}
