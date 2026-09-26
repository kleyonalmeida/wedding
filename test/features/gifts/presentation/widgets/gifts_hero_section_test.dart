import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_hero_section.dart';

void main() {
  group('GiftsHeroSection', () {
    testWidgets('should render all expected text and badges', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GiftsHeroSection(),
          ),
        ),
      );

      // Verify texts
      expect(find.text('Com Muito Amor & Gratidão'), findsOneWidget);
      expect(find.text('Lista de Presentes & Memórias'), findsOneWidget);
      
      // Verify badges
      expect(find.text('Experiências Reais'), findsOneWidget);
      expect(find.text('Contribuição Afetiva'), findsOneWidget);
      expect(find.text('Recado aos Noivos'), findsOneWidget);
      
      // Verify the widget uses animations (just by finding the widget tree contains FadeTransition or similar, 
      // but let's just make sure it renders without throwing for now)
      expect(find.byType(GiftsHeroSection), findsOneWidget);
    });
  });
}
