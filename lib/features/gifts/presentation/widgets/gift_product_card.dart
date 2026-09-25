import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gift_product.dart';
import 'gift_price.dart';

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

  @override
  Widget build(BuildContext context) {
    final card = MouseRegion(
      onEnter: (_) {
        if (widget.product.available) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.6),
              width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            if (_isHovered)
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTitle(context),
                      _buildActionSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.product.available) return card;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: Opacity(opacity: 0.72, child: card),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          color: isDark ? Colors.grey[900] : AppColors.surfaceContainerLow,
          padding: const EdgeInsets.all(16),
          child: AnimatedScale(
            scale: _isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: Image.network(
              widget.product.imageUrl,
              fit: BoxFit.contain,
              cacheWidth: (280 * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(280, 840)
                  .toInt(),
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported,
                color: AppColors.outlineVariant,
                size: 48,
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2));
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
                  isDark
                      ? Colors.grey[900]!.withValues(alpha: 0.5)
                      : AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return SizedBox(
      height:
          48, // Fix height to exactly 2 lines (18 * 1.2 * 2 ≈ 43.2, rounded up to 48 for safety)
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

  Widget _buildActionSection(BuildContext context) {
    return Column(
      children: [
        Text(
          formatGiftPrice(widget.product.priceCents),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.product.available ? widget.onGiftPressed : null,
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16)),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) return Colors.grey;
                if (states.contains(WidgetState.hovered)) {
                  // Mix primary with 20% black to make a darker brown
                  return Color.lerp(AppColors.primary, Colors.black, 0.2);
                }
                return AppColors.primary;
              }),
            ),
            child: Text(
              widget.product.available ? 'PRESENTEAR' : 'PRESENTEADO',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
