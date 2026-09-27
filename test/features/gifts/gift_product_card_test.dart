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
    expect(find.text('Inclui cartão de felicitações'), findsOneWidget);
    await tester.tap(find.text('Presentear os Noivos'));
    expect(presses, 1);
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
        greaterThan(300));
    expect(find.text('Presentear os Noivos'), findsOneWidget);
    expect(find.text('PRESENTEADO'), findsOneWidget);
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
