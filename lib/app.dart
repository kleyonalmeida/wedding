import 'package:flutter/material.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'dart:ui';
import 'core/theme/app_theme.dart';
import 'features/wedding/presentation/pages/wedding_page.dart';

class WeddingScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

class WeddingApp extends StatelessWidget {
  const WeddingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      initTheme: AppTheme.lightTheme,
      builder: (context, myTheme) {
        return MaterialApp(
          title: 'Kleyon & Liandra - Casamento',
          theme: myTheme,
          scrollBehavior: WeddingScrollBehavior(),
          home: const WeddingPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
