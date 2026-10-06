import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/gifts/data/models/gift_product.dart';
import 'package:wedding_app/features/gifts/presentation/controllers/cart_controller.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_product_card.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_product_grid.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_checkout_flow.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/cart_dialog.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/checkout_dialog.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_theme.dart';

GiftProduct product(int id) => GiftProduct(
    id: '$id',
    name: 'Presente especial $id',
    imageUrl: '',
    category: 'Casa',
    occasion: 'Todas',
    priceCents: 12500,
    isBestSeller: false,
    available: true,
    description: 'Carinho para as nossas manhãs.');

void main() {
  for (final width in [320.0, 390.0, 768.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('grid lazy sem overflow em $width / texto $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cart = CartController();
        addTearDown(cart.dispose);
        await tester.pumpWidget(MaterialApp(
            home: Builder(
                builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: Theme(
                        data: giftsTheme(context),
                        child: Scaffold(
                            body: CustomScrollView(slivers: [
                          GiftProductGrid(
                              products: List.generate(100, product),
                              isLoading: false,
                              hasMore: false,
                              onLoadMore: () {},
                              onRetry: () {},
                              cartController: cart),
                        ])))))));
        expect(find.byType(GiftProductCard).evaluate().length, lessThan(20));
        expect(tester.takeException(), isNull);
        expect(giftGridColumnCount(width, width, scale), width < 768 ? 2 : 4);
      });
    }
  }

  testWidgets('seleção direta não inclui itens existentes no carrinho',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cart = CartController()..addItem(product(2));
    addTearDown(cart.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () =>
                        showProductCheckout(context, product(1), cart, () {}),
                    child: const Text('Escolher'))))));
    await tester.tap(find.text('Escolher'));
    await tester.pumpAndSettle();
    expect(find.text('Presentear com Amor'), findsOneWidget);
    expect(find.text('Presente especial 2'), findsNothing);
    expect(cart.itemCount, 1);
    await tester.tap(find.text('Confirmar Presente'));
    await tester.pump();
    expect(find.text('Informe seu nome para o casal'), findsOneWidget);
    await tester.ensureVisible(find.text('Adicionar ao carrinho'));
    await tester.tap(find.text('Adicionar ao carrinho'));
    await tester.pumpAndSettle();
    expect(cart.itemCount, 2);
  });

  testWidgets('Apenas o Básico mostra a chave Pix sem abrir checkout',
      (tester) async {
    final cart = CartController();
    addTearDown(cart.dispose);
    final basic = GiftProduct(
      id: 'basic',
      name: 'Presente satírico',
      imageUrl: '',
      category: ' Apenas o Básico ',
      occasion: 'Todas',
      priceCents: 12000000000,
      isBestSeller: false,
      available: true,
    );
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showProductCheckout(context, basic, cart, () {}),
            child: const Text('Escolher'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Escolher'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Opaa, não pague por aqui não que tem imposto, aceitamos o pix, a chave é essa papai - c9388c93-cbed-4564-8b9d-bcb7f132e168 :)',
      ),
      findsOneWidget,
    );
    expect(find.text('Presentear com Amor'), findsNothing);
    await tester.tap(find.text('Adicionar ao carrinho'));
    await tester.pumpAndSettle();
    expect(cart.hasDirectPixOnly, isTrue);
  });

  testWidgets('carrinho bloqueado fecha e mantém aviso até clicar no X',
      (tester) async {
    final cart = CartController()
      ..addItem(GiftProduct(
        id: 'basic',
        name: 'Presente satírico',
        imageUrl: '',
        category: 'Apenas o Básico',
        occasion: 'Todas',
        priceCents: 12000000000,
        isBestSeller: false,
        available: true,
      ))
      ..addItem(product(2));
    addTearDown(cart.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showGiftCart(context, cart, () {}),
            child: const Text('Abrir carrinho'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir carrinho'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar compra'));
    await tester.pumpAndSettle();
    expect(find.byType(CartDialog), findsNothing);
    expect(find.byType(CheckoutDialog), findsNothing);
    expect(find.textContaining('c9388c93-cbed-4564-8b9d-bcb7f132e168'),
        findsOneWidget);
    await tester.pump(const Duration(minutes: 5));
    expect(find.textContaining('c9388c93-cbed-4564-8b9d-bcb7f132e168'),
        findsOneWidget);
    await tester.tap(find.byTooltip('Fechar aviso'));
    await tester.pumpAndSettle();
    expect(find.textContaining('c9388c93-cbed-4564-8b9d-bcb7f132e168'),
        findsNothing);

    cart.removeItem('basic');
    await tester.tap(find.text('Abrir carrinho'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar compra'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutDialog), findsOneWidget);
  });
}
