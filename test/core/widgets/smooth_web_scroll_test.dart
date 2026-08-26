import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/core/widgets/smooth_web_scroll.dart';

void main() {
  group('SmoothWebScroll Widget Tests', () {
    late ScrollController controller;

    setUp(() {
      controller = ScrollController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('Renders child correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothWebScroll(
              controller: controller,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('Scrolls when pointer scroll event is triggered', (WidgetTester tester) async {
      // Cria um container com altura grande para permitir rolagem
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothWebScroll(
              controller: controller,
              scrollAmount: 100.0,
              animationDuration: const Duration(milliseconds: 100),
              child: SingleChildScrollView(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  height: 2000,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      expect(controller.offset, 0.0);

      // Dispara um PointerScrollEvent simulando o scroll do mouse para baixo
      final center = tester.getCenter(find.byType(SmoothWebScroll));
      final gesture = await tester.startGesture(center, kind: PointerDeviceKind.mouse);
      await tester.sendEventToBinding(PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, 50), // Mouse scroll down
      ));
      
      // Avança a animação
      await tester.pumpAndSettle();

      // Verifica se a tela rolou o equivalente ao scrollAmount (100.0)
      expect(controller.offset, 100.0);
    });

    testWidgets('Does not scroll past max limits', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothWebScroll(
              controller: controller,
              scrollAmount: 2000.0, // Scroll gigante
              animationDuration: const Duration(milliseconds: 100),
              child: SingleChildScrollView(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  height: 1000, // Altura total é 1000, mas a tela ocupa parte (ex: 600), maxScroll < 1000
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      expect(controller.offset, 0.0);

      // Dispara o evento de scroll para baixo
      final center = tester.getCenter(find.byType(SmoothWebScroll));
      final gesture = await tester.startGesture(center, kind: PointerDeviceKind.mouse);
      await tester.sendEventToBinding(PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, 50), // Mouse scroll down
      ));
      
      await tester.pumpAndSettle();

      // O offset não deve ser 2000, deve ser travado no maxScrollExtent
      expect(controller.offset, equals(controller.position.maxScrollExtent));
    });
  });
}
