import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/core/theme/app_theme.dart';
import 'package:wedding_app/features/wedding/presentation/widgets/wedding_header.dart';

void main() {
  group('WeddingHeader Widget Tests', () {
    testWidgets('Renders K&L logo and menu items correctly on wide screen', (WidgetTester tester) async {
      // Definir tamanho da tela para modo desktop (largura > 900)
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      // Ensure that we restore the window size after the test
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool homeTapped = false;
      bool rsvpTapped = false;

      await tester.pumpWidget(
        ThemeProvider(
          initTheme: AppTheme.lightTheme,
          builder: (context, theme) => MaterialApp(
            theme: theme,
            home: Scaffold(
              body: WeddingHeader(
                isScrolled: false,
                onHomeTap: () => homeTapped = true,
                onCasalTap: () {},
                onRecepcaoTap: () {},
                onListaTap: () {},
                onRsvpTap: () => rsvpTapped = true,
              ),
            ),
          ),
        ),
      );

      // Verifica se a logo está presente
      expect(find.text('K&L'), findsOneWidget);

      // Verifica se as opções do menu estão presentes
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('O CASAL'), findsOneWidget);
      expect(find.text('RECEPÇÃO'), findsOneWidget);
      expect(find.text('LISTA DE PRESENTES'), findsOneWidget);
      
      // Verifica se o botão RSVP está presente
      expect(find.text('PRESENÇA'), findsOneWidget);

      // Testa interações
      await tester.tap(find.text('HOME'));
      expect(homeTapped, isTrue);

      await tester.tap(find.text('PRESENÇA'));
      expect(rsvpTapped, isTrue);
    });

    testWidgets('Shows hamburger menu on small screens', (WidgetTester tester) async {
      // Definir tamanho da tela para modo mobile (largura < 900)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool menuTapped = false;

      await tester.pumpWidget(
        ThemeProvider(
          initTheme: AppTheme.lightTheme,
          builder: (context, theme) => MaterialApp(
            theme: theme,
            home: Scaffold(
              body: WeddingHeader(
                isScrolled: false,
                onHomeTap: () {},
                onCasalTap: () {},
                onRecepcaoTap: () {},
                onListaTap: () {},
                onRsvpTap: () {},
                onMenuTap: () => menuTapped = true,
              ),
            ),
          ),
        ),
      );

      // Verifica se a logo está presente
      expect(find.text('K&L'), findsOneWidget);

      // Opções completas não devem aparecer na tela pequena
      expect(find.text('HOME'), findsNothing);
      expect(find.text('O CASAL'), findsNothing);

      // O ícone do menu sanduíche deve estar presente
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Testa a interação do menu
      await tester.tap(find.byIcon(Icons.menu));
      expect(menuTapped, isTrue);
    });
  });
}
