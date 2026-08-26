import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gift_product.dart';

class GiftProductCard extends StatefulWidget {
  final GiftProduct product;
  final VoidCallback onGiftPressed;

  const GiftProductCard({
    super.key,
    required this.product,
    required this.onGiftPressed,
  });

  @override
  State<GiftProductCard> createState() => _GiftProductCardState();
}

class _GiftProductCardState extends State<GiftProductCard> {
  bool _isHovered = false;

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            if (_isHovered)
              BoxShadow(
                color: AppColors.primaryContainer.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTitle(context),
                      _buildPriceSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          height: 192,
          width: double.infinity,
          color: isDark ? Colors.grey[900] : AppColors.surfaceContainerLow,
          padding: const EdgeInsets.all(16),
          child: AnimatedScale(
            scale: _isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: Image.network(
              widget.product.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported,
                color: AppColors.outlineVariant,
                size: 48,
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  isDark ? Colors.grey[900]!.withOpacity(0.5) : AppColors.surfaceContainerLow.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        if (widget.product.discountPercentage > 0)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '-${widget.product.discountPercentage}%',
                style: const TextStyle(
                  color: AppColors.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return SizedBox(
      height: 48, // Fix height to exactly 2 lines (18 * 1.2 * 2 ≈ 43.2, rounded up to 48 for safety)
      child: Align(
        alignment: Alignment.topCenter,
        child: Text(
          widget.product.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Bodoni Moda',
            fontSize: 18,
            height: 1.2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.product.originalPrice > widget.product.currentPrice)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 2.0),
                child: Text(
                  _formatCurrency(widget.product.originalPrice),
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            Text(
              _formatCurrency(widget.product.currentPrice),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.product.installments}x de ${_formatCurrency(widget.product.installmentValue)} sem juros',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onGiftPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'PRESENTEAR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
