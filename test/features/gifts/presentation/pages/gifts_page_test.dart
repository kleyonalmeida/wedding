import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wedding_app/core/network/api_client.dart';
import 'package:wedding_app/features/gifts/data/repositories/gift_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/gifts/presentation/pages/gifts_page.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_hero_section.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_category_chips.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_product_grid.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_closing_section.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_filter_panel.dart';
import 'package:wedding_app/features/wedding/presentation/widgets/wedding_header.dart';
import 'package:wedding_app/features/wedding/presentation/widgets/wedding_footer.dart';
import 'package:wedding_app/core/widgets/smooth_web_scroll.dart';

void main() {
  Widget createWidgetUnderTest([List<Map<String, Object>> catalog = const []]) {
    return MaterialApp(
        home: GiftsPage(
            repository: GiftRepository(
                apiClient: ApiClient(
                    client: MockClient((_) async =>
                        http.Response(jsonEncode(catalog), 200))))));
  }

  group('GiftsPage', () {
    testWidgets('filtros mostram e aplicam categorias do catálogo',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest([
        {
          'id': '1',
          'name': 'Presente 1',
          'category': 'Apenas o Básico',
          'priceCents': 1000,
        },
        {
          'id': '2',
          'name': 'Presente 2',
          'category': 'Viagem espacial',
          'priceCents': 2000,
        },
      ]));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(GiftsCategoryChips), 500,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Apenas o Básico'), findsOneWidget);
      expect(find.text('Viagem espacial'), findsOneWidget);
      expect(find.text('Nosso Novo Lar'), findsNothing);

      await tester.tap(find.text('Viagem espacial'));
      await tester.pumpAndSettle();
      final grid = tester.widget<GiftProductGrid>(find.byType(GiftProductGrid));
      expect(grid.products.map((p) => p.name), ['Presente 2']);
    });

    testWidgets('renders all expected new sections and removes old ones',
        (tester) async {
      // For network images in tests we just let flutter handle them since they just return 400.
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should find WeddingHeader
      expect(find.byType(WeddingHeader), findsOneWidget);
      expect(find.byType(GiftsHeroSection), findsOneWidget);

      final scrollableFinder = find.byType(Scrollable).first;

      await tester.scrollUntilVisible(find.byType(GiftsCategoryChips), 500.0,
          scrollable: scrollableFinder);
      expect(find.byType(GiftsCategoryChips), findsOneWidget);

      await tester.scrollUntilVisible(
          find.text('Nenhum produto encontrado com os filtros selecionados.'),
          200.0,
          scrollable: scrollableFinder);
      expect(find.byType(GiftProductGrid), findsOneWidget);

      await tester.scrollUntilVisible(find.byType(GiftsClosingSection), 500.0,
          scrollable: scrollableFinder);
      expect(find.byType(GiftsClosingSection), findsOneWidget);

      await tester.scrollUntilVisible(find.byType(WeddingFooter), 500.0,
          scrollable: scrollableFinder);
      expect(find.byType(WeddingFooter), findsOneWidget);

      // Should NOT find the old filter panel (sidebar)
      expect(find.byType(GiftFilterPanel), findsNothing);
      // The mobile filter button should also be gone
      expect(find.text('Filtros'), findsNothing);
    });

    testWidgets('uses native scroll by default and no SmoothWebScroll',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // SmoothWebScroll shouldn't be present
      expect(find.byType(SmoothWebScroll), findsNothing);

      // Scroll physics shouldn't be NeverScrollableScrollPhysics
      final customScrollViewFinder = find.byType(CustomScrollView);
      expect(customScrollViewFinder, findsOneWidget);

      final customScrollView =
          tester.widget<CustomScrollView>(customScrollViewFinder);
      expect(
          customScrollView.physics, isNot(isA<NeverScrollableScrollPhysics>()));
    });
  });
}
