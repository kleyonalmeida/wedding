import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_category_chips.dart';

void main() {
  group('GiftsCategoryChips', () {
    testWidgets('mostra apenas as categorias cadastradas e a busca',
        (WidgetTester tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GiftsCategoryChips(
              categories: const ['Apenas o Básico', 'Viagem espacial'],
              selectedCategory: selected,
              onCategoryChanged: (v) => selected = v,
              onSearchChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Todas as Lembranças'), findsOneWidget);
      expect(find.text('Apenas o Básico'), findsOneWidget);
      expect(find.text('Viagem espacial'), findsOneWidget);
      expect(find.text('Nosso Novo Lar'), findsNothing);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar presente...'), findsOneWidget);
    });

    testWidgets('should call callbacks on interaction',
        (WidgetTester tester) async {
      String? selected;
      String search = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GiftsCategoryChips(
              categories: const ['Casa', 'Apenas o Básico'],
              selectedCategory: selected,
              onCategoryChanged: (v) => selected = v,
              onSearchChanged: (v) => search = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Apenas o Básico'));
      await tester.pumpAndSettle();
      expect(selected, 'Apenas o Básico');

      await tester.tap(find.text('Todas as Lembranças'));
      await tester.pumpAndSettle();
      expect(selected, isNull);

      await tester.enterText(find.byType(TextField), 'Panela');
      await tester.pumpAndSettle();
      expect(search, 'Panela');
    });
  });
}
