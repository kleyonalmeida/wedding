import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gift_product.dart';
import '../controllers/cart_controller.dart';
import 'gift_product_card.dart';
import 'cart_dialog.dart';
import 'checkout_dialog.dart';

class GiftProductGrid extends StatelessWidget {
  final List<GiftProduct> products;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final String? error;
  final VoidCallback onRetry;
  final CartController cartController;

  const GiftProductGrid({
    super.key,
    required this.products,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    this.error,
    required this.onRetry,
    required this.cartController,
  });

  void _handleGiftPressed(BuildContext context, GiftProduct product) {
    if (!product.available) return;
    cartController.addItem(product);
    showDialog(
      context: context,
      builder: (ctx) => CartDialog(
        cartController: cartController,
        onCheckout: () {
          Navigator.of(ctx).pop();
          showDialog(
            context: context,
            builder: (ctx2) => CheckoutDialog(
              cartController: cartController,
              onCatalogChanged: onRetry,
              onBack: () {
                Navigator.of(ctx2).pop();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty && !isLoading) {
      if (error != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, style: const TextStyle(color: AppColors.dark)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        );
      }
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Nenhum produto encontrado com os filtros selecionados.',
            style: TextStyle(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                ((constraints.maxWidth + 24) / 304).floor().clamp(1, 4).toInt();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 370,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return GiftProductCard(
                  product: product,
                  onGiftPressed: () => _handleGiftPressed(context, product),
                );
              },
            );
          },
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          )
        else if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 48.0, bottom: 24.0),
            child: Center(
              child: OutlinedButton(
                onPressed: onLoadMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  'CARREGAR MAIS',
                  style: TextStyle(
                      letterSpacing: 2.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
