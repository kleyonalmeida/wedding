import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/gift_product.dart';
import '../controllers/cart_controller.dart';
import 'gift_product_card.dart';
import 'gift_checkout_flow.dart';

/// A sliver: place directly in CustomScrollView.slivers.
class GiftProductGrid extends StatelessWidget {
  final List<GiftProduct> products;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final String? error;
  final VoidCallback onRetry;
  final CartController cartController;

  const GiftProductGrid(
      {super.key,
      required this.products,
      required this.isLoading,
      required this.hasMore,
      required this.onLoadMore,
      this.error,
      required this.onRetry,
      required this.cartController});

  @override
  Widget build(BuildContext context) =>
      SliverLayoutBuilder(builder: (context, constraints) {
        final viewport = MediaQuery.sizeOf(context).width;
        final margin = viewport < 768 ? 20.0 : 32.0;
        final horizontal =
            math.max(margin, (constraints.crossAxisExtent - 1200) / 2);
        final width = constraints.crossAxisExtent - horizontal * 2;
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final desired = viewport < 768
            ? 1
            : viewport < 1024
                ? 2
                : 3;
        final columns = math.min(
            desired,
            math.max(
                1, ((width + 32) / (280 * math.sqrt(scale) + 32)).floor()));
        final cardWidth = (width - 32 * (columns - 1)) / columns;
        final accessibilitySpace =
            scale > 1 && cardWidth < 400 ? 200 * (scale - 1) : 0.0;
        final extent = 256 +
            48 +
            58 * scale +
            10 +
            64 * scale +
            190 * scale +
            accessibilitySpace;
        final status = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (isLoading)
                const CircularProgressIndicator()
              else if (error != null) ...[
                Text(error!, textAlign: TextAlign.center),
                TextButton(
                    onPressed: onRetry, child: const Text('Tentar Novamente')),
              ] else if (products.isEmpty)
                const Text(
                    'Nenhum produto encontrado com os filtros selecionados.')
              else if (hasMore)
                OutlinedButton(
                    onPressed: onLoadMore, child: const Text('CARREGAR MAIS')),
            ]));
        return SliverMainAxisGroup(slivers: [
          SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: extent,
                    crossAxisSpacing: 32,
                    mainAxisSpacing: 32),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = products[index];
                  return GiftProductCard(
                      key: ValueKey(product.id),
                      product: product,
                      onGiftPressed: () => showProductCheckout(
                          context, product, cartController, onRetry));
                }, childCount: products.length),
              )),
          SliverToBoxAdapter(child: status),
        ]);
      });
}
