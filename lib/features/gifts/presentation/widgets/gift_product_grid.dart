import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gift_product.dart';
import 'gift_product_card.dart';

class GiftProductGrid extends StatelessWidget {
  final List<GiftProduct> products;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final String? error;
  final VoidCallback onRetry;

  const GiftProductGrid({
    super.key,
    required this.products,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    this.error,
    required this.onRetry,
  });

  Future<void> _handleGiftPressed(BuildContext context, GiftProduct product) async {
    final uri = Uri.tryParse(product.giftUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link do presente.')),
        );
      }
    }
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            childAspectRatio: 0.62,
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  'CARREGAR MAIS',
                  style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
