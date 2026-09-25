import 'dart:ui';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/theme_wave_transition.dart';

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

class WeddingApp extends StatefulWidget {
  const WeddingApp({super.key});

  @override
  State<WeddingApp> createState() => _WeddingAppState();
}

class _WeddingAppState extends State<WeddingApp> {
  final AppRouterDelegate _routerDelegate = AppRouterDelegate();
  final AppRouteInformationParser _routeParser = AppRouteInformationParser();

  @override
  Widget build(BuildContext context) => ThemeProvider(
        initTheme: AppTheme.lightTheme,
        duration: const Duration(milliseconds: 1500),
        builder: (context, myTheme) => MaterialApp.router(
          title: 'Kleyon & Liandra - Casamento',
          theme: myTheme,
          routerDelegate: _routerDelegate,
          routeInformationParser: _routeParser,
          builder: (context, child) => ThemeWaveTransition(
            child: child ?? const SizedBox.shrink(),
          ),
          scrollBehavior: WeddingScrollBehavior(),
          debugShowCheckedModeBanner: false,
        ),
      );

  @override
  void dispose() {
    _routerDelegate.dispose();
    super.dispose();
  }
}
