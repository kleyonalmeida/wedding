import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_dedication_modal.dart';

void main() {
  group('GiftDedicationModal', () {
    testWidgets('should render modal with expected elements for fixed price', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GiftDedicationModal(
              itemTitle: 'Jantar à Luz de Velas',
              itemValue: 'R\$ 420,00',
              isCustomAmount: false,
              onClose: () {},
              onConfirm: (name, message, customAmount) {},
            ),
          ),
        ),
      );

      // Header elements
      expect(find.text('Presentear com Amor'), findsOneWidget);
      expect(find.text('Jantar à Luz de Velas'), findsOneWidget);
      expect(find.text('Sugerido: R\$ 420,00'), findsOneWidget);

      // Form fields
      expect(find.text('Seu Nome / Família'), findsOneWidget);
      expect(find.text('Sua Mensagem aos Noivos'), findsOneWidget);
      expect(find.text('Valor da Contribuição (R\$)'), findsNothing); // Should be hidden for fixed price

      // Info box
      expect(find.text('Ambiente seguro e afetivo'), findsOneWidget);
      expect(find.text('PIX ou Cartão'), findsOneWidget);

      // Buttons
      expect(find.text('Voltar'), findsOneWidget);
      expect(find.text('Confirmar Presente'), findsOneWidget);
    });

    testWidgets('should render custom amount field when isCustomAmount is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GiftDedicationModal(
              itemTitle: 'Presente Personalizado',
              itemValue: 'Valor a definir por você',
              isCustomAmount: true,
              onClose: () {},
              onConfirm: (name, message, customAmount) {},
            ),
          ),
        ),
      );

      expect(find.text('Valor da Contribuição (R\$)'), findsOneWidget);
      expect(find.text('Presente Personalizado'), findsOneWidget);
    });

    testWidgets('should trigger callbacks correctly', (WidgetTester tester) async {
      bool closeCalled = false;
      String? submittedName;
      String? submittedMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GiftDedicationModal(
              itemTitle: 'Item Teste',
              itemValue: 'R\$ 100',
              isCustomAmount: false,
              onClose: () {
                closeCalled = true;
              },
              onConfirm: (name, message, customAmount) {
                submittedName = name;
                submittedMessage = message;
              },
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(
        find.widgetWithText(TextField, 'Ex: Tio Carlos e Família'),
        'João Silva',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Escreva algumas palavras doces para aquecer nossos corações...'),
        'Felicidades!',
      );

      // Submit
      await tester.ensureVisible(find.text('Confirmar Presente'));
      await tester.tap(find.text('Confirmar Presente'));
      await tester.pump();

      expect(submittedName, 'João Silva');
      expect(submittedMessage, 'Felicidades!');

      // Close
      await tester.ensureVisible(find.text('Voltar'));
      await tester.tap(find.text('Voltar'));
      await tester.pump();

      expect(closeCalled, true);
    });
  });
}
