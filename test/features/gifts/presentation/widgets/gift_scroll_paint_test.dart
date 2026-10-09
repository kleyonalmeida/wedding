import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/gifts/data/models/gift_product.dart';
import 'package:wedding_app/features/gifts/presentation/controllers/cart_controller.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_product_card.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gift_product_grid.dart';

GiftProduct _product(int id) => GiftProduct(
      id: '$id',
      name: 'Presente $id',
      imageUrl: '',
      category: 'Casa',
      occasion: 'Todas',
      priceCents: 10000,
      isBestSeller: false,
      available: true,
    );

List<PictureLayer> _pictures(RenderRepaintBoundary boundary) {
  final pictures = <PictureLayer>[];
  void visit(Layer layer) {
    if (layer is PictureLayer) pictures.add(layer);
    if (layer is ContainerLayer) {
      Layer? child = layer.firstChild;
      while (child != null) {
        visit(child);
        child = child.nextSibling;
      }
    }
  }

  visit(boundary.debugLayer!);
  return pictures;
}

void main() {
  testWidgets('hover repinta apenas o cartão afetado', (tester) async {
    final cart = CartController();
    addTearDown(cart.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: CustomScrollView(slivers: [
        GiftProductGrid(
          products: List.generate(8, _product),
          isLoading: false,
          hasMore: false,
          onLoadMore: () {},
          onRetry: () {},
          cartController: cart,
        ),
      ])),
    ));
    await tester.pumpAndSettle();
    RenderRepaintBoundary boundary(int index) => tester.renderObject(
          find
              .descendant(
                of: find.byType(GiftProductCard).at(index),
                matching: find.byType(RepaintBoundary),
              )
              .first,
        );
    final hovered = boundary(0);
    final neighbor = boundary(1);
    final hoveredBefore = _pictures(hovered);
    final neighborBefore = _pictures(neighbor);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(0, 0));
    await mouse.moveTo(tester.getCenter(find.byType(GiftProductCard).first));
    await tester.pumpAndSettle();
    expect(_pictures(hovered), isNot(equals(hoveredBefore)));
    expect(neighborBefore, isNotEmpty);
    expect(_pictures(neighbor), orderedEquals(neighborBefore));
    await mouse.removePointer();
    await tester.pumpAndSettle();
  });

  testWidgets('rolar catálogo longo mantém construção sob demanda',
      (tester) async {
    final cart = CartController();
    final scroll = ScrollController();
    addTearDown(cart.dispose);
    addTearDown(scroll.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: CustomScrollView(controller: scroll, slivers: [
        GiftProductGrid(
          products: List.generate(100, _product),
          isLoading: false,
          hasMore: false,
          onLoadMore: () {},
          onRetry: () {},
          cartController: cart,
        ),
      ])),
    ));
    await tester.pumpAndSettle();
    scroll.jumpTo(3000);
    await tester.pumpAndSettle();
    expect(find.byType(GiftProductCard).evaluate().length, lessThan(24));
    expect(find.text('Presente 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
