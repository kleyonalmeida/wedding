import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/gifts/data/models/gift_product.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_product_card.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_product_grid.dart';
import 'package:wedding_app/features/gifts/presentation/controllers/cart_controller.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_price.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/cart_dialog.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/checkout_dialog.dart';

void main() {
  GiftProduct gift({required bool available}) => GiftProduct(
        id: 'gift-1',
        name: 'Presente de casamento',
        imageUrl: '',
        category: 'Casa',
        occasion: 'Todas',
        priceCents: 4321,
        isBestSeller: false,
        available: available,
        description: 'Um belo presente para os noivos',
      );

  test('carrinho soma centavos e formata reais', () {
    final cart = CartController();
    cart.addItem(gift(available: true));
    cart.addItem(gift(available: true));
    expect(cart.totalCents, 8642);
    expect(formatGiftPrice(123456), 'R\$ 1.234,56');
  });

  testWidgets('presente esgotado fica cinza e não pode ser selecionado',
      (tester) async {
    var presses = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 350,
          height: 600,
          child: GiftProductCard(
            product: gift(available: false),
            onGiftPressed: () => presses++,
          ),
        ),
      ),
    ));
    expect(find.text('PRESENTEADO'), findsOneWidget);
    expect(find.byType(ColorFiltered), findsWidgets);
    expect(find.text('R\$ 43,21'), findsOneWidget);
    expect(find.text('NOSSO NOVO LAR'), findsOneWidget);
    expect(find.text('Um belo presente para os noivos'), findsOneWidget);
    await tester.tap(find.text('PRESENTEADO'));
    expect(presses, 0);
  });

  testWidgets('presente disponível mostra valor e pode ser selecionado',
      (tester) async {
    var presses = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 350,
          height: 600,
          child: GiftProductCard(
            product: gift(available: true),
            onGiftPressed: () => presses++,
          ),
        ),
      ),
    ));
    expect(find.text('R\$ 43,21'), findsOneWidget);
    expect(find.text('Presentear os Noivos'), findsOneWidget);
    await tester.tap(find.text('Presentear os Noivos'));
    expect(presses, 1);
  });

  testWidgets('detalhes do presente mostram o preço formatado', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 350,
          height: 600,
          child: GiftProductCard(
            product: gift(available: true),
            onGiftPressed: () {},
          ),
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.image_not_supported_outlined).first);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('R\$ 43,21'), findsNWidgets(2));
  });

  testWidgets('grade móvel mantém botão inteiro em uma coluna', (tester) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cart = CartController();
    addTearDown(cart.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CustomScrollView(slivers: [
      GiftProductGrid(
          products: [gift(available: true), gift(available: false)],
          isLoading: false,
          hasMore: false,
          onLoadMore: () {},
          onRetry: () {},
          cartController: cart),
    ]))));
    expect(tester.getSize(find.byType(GiftProductCard).first).width,
        greaterThan(140));
    expect(find.text('Presentear os Noivos'), findsOneWidget);
    expect(find.text('PRESENTEADO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ver mais expande o card até o texto completo', (tester) async {
    const longText =
        'Um texto curto na vitrine que não conta a história inteira do presente.';
    const fullText =
        'Um texto curto na vitrine que não conta a história inteira do presente. '
        'Quando o convidado pede para ver mais, o card acompanha este parágrafo completo, '
        'sem reservar uma área branca vazia antes da leitura.';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 280,
              child: GiftProductCard(
                product: GiftProduct(
                  id: 'gift-long',
                  name: 'Jantar especial dos noivos em uma noite longa',
                  imageUrl: '',
                  category: 'Casa',
                  occasion: 'Todas',
                  priceCents: 1000,
                  isBestSeller: false,
                  available: true,
                  description: longText,
                  fullDescription: fullText,
                ),
                onGiftPressed: () {},
              ),
            ),
          ),
        ),
      ),
    ));

    expect(find.text('Ver mais'), findsOneWidget);
    expect(find.text(fullText), findsNothing);
    final collapsed = tester.getSize(find.byType(GiftProductCard));

    await tester.tap(find.text('Ver mais'));
    await tester.pumpAndSettle();

    expect(find.text('Ver menos'), findsOneWidget);
    expect(find.text(fullText), findsOneWidget);
    expect(tester.getSize(find.byType(GiftProductCard)).height,
        greaterThan(collapsed.height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cards fechados compartilham a mesma altura da faixa branca',
      (tester) async {
    Widget card(GiftProduct product) => SizedBox(
          width: 280,
          child: GiftProductCard(product: product, onGiftPressed: () {}),
        );

    GiftProduct item(String id, String name, String description) => GiftProduct(
          id: id,
          name: name,
          imageUrl: '',
          category: 'Casa',
          occasion: 'Todas',
          priceCents: 1000,
          isBestSeller: false,
          available: true,
          description: description,
        );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            card(item('a', 'Mesa', 'Curta')),
            card(item(
              'b',
              'Jantar especial dos noivos em uma noite longa',
              'Um texto curto na vitrine que não conta a história inteira do presente.',
            )),
          ],
        ),
      ),
    ));

    final sizes = find.byType(GiftProductCard);
    expect(tester.getSize(sizes.at(0)).height,
        tester.getSize(sizes.at(1)).height);
    expect(tester.takeException(), isNull);
  });

  testWidgets('carrinho e resumo exibem total no celular', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cart = CartController()..addItem(gift(available: true));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CartDialog(cartController: cart, onCheckout: () {})),
    ));
    expect(find.text('R\$ 43,21'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CheckoutDialog(cartController: cart, onBack: () {}),
      ),
    ));
    expect(find.text('R\$ 43,21'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
