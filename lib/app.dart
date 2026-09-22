import 'package:flutter/material.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'dart:ui';
import 'core/theme/app_theme.dart';
import 'core/widgets/theme_wave_transition.dart';
import 'features/wedding/presentation/pages/wedding_page.dart';
import 'features/gifts/presentation/pages/gifts_page.dart';

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
      duration: const Duration(milliseconds: 1500),
      builder: (context, myTheme) {
        return MaterialApp(
          title: 'Kleyon & Liandra - Casamento',
          theme: myTheme,
          builder: (context, child) {
            return ThemeWaveTransition(
              child: child ?? const SizedBox.shrink(),
            );
          },
          scrollBehavior: WeddingScrollBehavior(),
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const WeddingPage());
              case '/presentes':
                return PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const GiftsPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                );
              default:
                return MaterialPageRoute(builder: (_) => const WeddingPage());
            }
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
