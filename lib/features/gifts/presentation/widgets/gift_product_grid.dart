import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/gift_product.dart';
import '../controllers/cart_controller.dart';
import 'gift_product_card.dart';
import 'gift_checkout_flow.dart';

int giftGridColumnCount(double viewport, double crossAxisExtent, double scale) {
  assert(crossAxisExtent > 0 && scale > 0);
  return viewport < 768 ? 2 : 4;
}

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
        final margin = viewport < 768 ? 16.0 : 32.0;
        final gap = viewport < 768 ? 12.0 : 16.0;
        final horizontal =
            math.max(margin, (constraints.crossAxisExtent - 1200) / 2);
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final columns =
            giftGridColumnCount(viewport, constraints.crossAxisExtent, scale);
        final rowCount =
            products.isEmpty ? 0 : (products.length / columns).ceil();
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
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final start = index * columns;
                  final end = math.min(start + columns, products.length);
                  return Padding(
                    padding: EdgeInsets.only(bottom: gap),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var column = 0; column < columns; column++) ...[
                          if (column > 0) SizedBox(width: gap),
                          Expanded(
                            child: start + column < end
                                ? GiftProductCard(
                                    key: ValueKey(products[start + column].id),
                                    product: products[start + column],
                                    onGiftPressed: () => showProductCheckout(
                                        context,
                                        products[start + column],
                                        cartController,
                                        onRetry),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  );
                }, childCount: rowCount),
              )),
          SliverToBoxAdapter(child: status),
        ]);
      });
}
