import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gift_product.dart';
import 'gift_price.dart';
import '../../data/models/gift_category.dart';

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
                      horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleAndDescription(context),
                      const Spacer(),
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
          height: 256,
          width: double.infinity,
          color: isDark ? Colors.grey[900] : AppColors.surfaceContainerLow,
          child: ClipRect(
            child: AnimatedScale(
              scale: _isHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: LayoutBuilder(
                  builder: (context, constraints) => widget
                          .product.imageUrl.isEmpty
                      ? const Center(
                          child: Icon(Icons.image_not_supported_outlined,
                              size: 48))
                      : Image.network(
                          widget.product.imageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: (constraints.maxWidth *
                                  MediaQuery.devicePixelRatioOf(context))
                              .round()
                              .clamp(256, 1200)
                              .toInt(),
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.image_not_supported,
                            color: AppColors.outlineVariant,
                            size: 48,
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                                child: Icon(Icons.image_outlined, size: 48));
                          },
                        )),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[900]!.withValues(alpha: 0.9)
                      : AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  giftCategoryLabel(widget.product.category).toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              )),
        ),
      ],
    );
  }

  Widget _buildTitleAndDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 24,
            height: 1.2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (widget.product.description != null &&
            widget.product.description!.isNotEmpty)
          Text(
            widget.product.description!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text('PRESENTE SUGERIDO',
                style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: colors.onSurfaceVariant)),
            Text(formatGiftPrice(widget.product.priceCents),
                style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.primary)),
          ]),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: widget.product.available ? widget.onGiftPressed : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
          child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (widget.product.available)
                  const Icon(Icons.redeem, size: 18),
                Text(
                    widget.product.available
                        ? 'Presentear os Noivos'
                        : 'PRESENTEADO',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans', fontSize: 12)),
              ])),
      const SizedBox(height: 12),
      Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Icon(Icons.chat_bubble_outline, size: 14, color: colors.secondary),
            Text('Inclui cartão de felicitações',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          ]),
    ]);
  }
}
