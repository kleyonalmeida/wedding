import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/wedding/presentation/pages/wedding_page.dart';

class WeddingApp extends StatelessWidget {
  const WeddingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kleyon & Liandra - Casamento',
      theme: AppTheme.lightTheme,
      home: const WeddingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
