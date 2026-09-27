import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_closing_section.dart';

void main() {
  group('GiftsClosingSection', () {
    testWidgets('should render icon, title, and body text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GiftsClosingSection(),
          ),
        ),
      );

      // Verify the icon
      expect(find.byIcon(Icons.auto_stories), findsOneWidget);

      // Verify the title
      expect(find.text('Memórias que duram para sempre'), findsOneWidget);

      // Verify the body text
      expect(
        find.text(
            'Agradecemos profundamente por sonhar este novo capítulo ao nosso lado. Cada gesto de carinho ilumina ainda mais o caminho até o nosso "Sim".'),
        findsOneWidget,
      );
    });

    testWidgets('should have max width constraint and correct padding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: GiftsClosingSection()),
          ),
        ),
      );

      final paddingFinder = find.byKey(const Key('closing_section_padding'));
      final paddingWidget = tester.widget<Padding>(paddingFinder);

      // Expected padding vertical 24px (py-6)
      expect(paddingWidget.padding.resolve(TextDirection.ltr).top, 24.0);
      expect(paddingWidget.padding.resolve(TextDirection.ltr).bottom, 24.0);

      final containerFinder =
          find.byKey(const Key('closing_section_constraints'));
      final containerWidget = tester.widget<ConstrainedBox>(containerFinder);

      expect(containerWidget.constraints.maxWidth, 672.0);
    });
  });
}
