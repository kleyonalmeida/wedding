import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_category_chips.dart';

void main() {
  group('GiftsCategoryChips', () {
    testWidgets('should render all chips and a search field', (WidgetTester tester) async {
      String selected = 'todas';
      String search = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GiftsCategoryChips(
              selectedCategory: selected,
              onCategoryChanged: (v) => selected = v,
              onSearchChanged: (v) => search = v,
            ),
          ),
        ),
      );

      // Verify Chips
      expect(find.text('Todas as Lembranças'), findsOneWidget);
      expect(find.text('Lua de Mel & Experiências'), findsOneWidget);
      expect(find.text('Nosso Novo Lar'), findsOneWidget);
      expect(find.text('Jantares & Momentos'), findsOneWidget);
      expect(find.text('Cotas Flexíveis'), findsOneWidget);

      // Verify Search Field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar presentes...'), findsOneWidget); // Hint text
    });

    testWidgets('should call callbacks on interaction', (WidgetTester tester) async {
      String selected = 'todas';
      String search = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GiftsCategoryChips(
              selectedCategory: selected,
              onCategoryChanged: (v) => selected = v,
              onSearchChanged: (v) => search = v,
            ),
          ),
        ),
      );

      // Tap on a different chip
      await tester.tap(find.text('Nosso Novo Lar'));
      await tester.pumpAndSettle();
      expect(selected, 'lar');

      // Enter text in search field
      await tester.enterText(find.byType(TextField), 'Panela');
      await tester.pumpAndSettle();
      expect(search, 'Panela');
    });
  });
}
