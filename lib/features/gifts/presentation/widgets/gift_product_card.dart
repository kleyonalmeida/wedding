import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gift_product.dart';
import 'gift_price.dart';
import '../../data/models/gift_category.dart';

double giftCardImageHeightFor(double cardWidth) {
  if (cardWidth < 200) return 92;
  if (cardWidth < 260) return 108;
  return 124;
}

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
  bool _expanded = false;

  bool _exceedsLines(String text, TextStyle style, double maxWidth, int lines) {
    if (text.isEmpty || !maxWidth.isFinite) return false;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: lines,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = constraints.maxWidth;
      final compact = cardWidth < 220;
      final imageHeight = giftCardImageHeightFor(cardWidth);
      final horizontalPad = compact ? 10.0 : 14.0;
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(context, imageHeight),
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPad, compact ? 10 : 12,
                      horizontalPad, compact ? 10 : 12),
                  child: _buildBody(context, compact: compact),
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
    });
  }

  Widget _buildImageSection(BuildContext context, double imageHeight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          height: imageHeight,
          width: double.infinity,
          color: isDark ? Colors.grey[900] : AppColors.surfaceContainerLow,
          child: LayoutBuilder(
            builder: (context, constraints) => widget.product.imageUrl.isEmpty
                ? const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 48))
                : Image.network(
                    widget.product.imageUrl,
                    width: constraints.maxWidth,
                    height: imageHeight,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    cacheWidth: (constraints.maxWidth *
                            MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(160, 1200)
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
                          child: Icon(Icons.image_outlined, size: 48));
                    },
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

  Widget _buildBody(BuildContext context, {required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    final shortText = widget.product.description?.trim() ?? '';
    final fullText = (widget.product.fullDescription?.trim().isNotEmpty == true)
        ? widget.product.fullDescription!.trim()
        : shortText;
    final preview = shortText.isNotEmpty ? shortText : fullText;
    final titleStyle = TextStyle(
      fontFamily: 'Playfair Display',
      fontSize: compact ? 16 : 18,
      height: 1.2,
      color: colors.onSurface,
    );
    final bodyStyle = TextStyle(
      fontSize: compact ? 12 : 13,
      height: 1.35,
      color: colors.onSurfaceVariant,
    );

    return LayoutBuilder(builder: (context, constraints) {
      final titleOverflows = _exceedsLines(
          widget.product.name, titleStyle, constraints.maxWidth, 1);
      final previewOverflows =
          _exceedsLines(preview, bodyStyle, constraints.maxWidth, 1);
      final hasHiddenText = fullText.isNotEmpty && fullText != preview;
      final canExpand = titleOverflows || previewOverflows || hasHiddenText;
      final showFull = _expanded && canExpand;

      final scale = MediaQuery.textScalerOf(context).scale(1);
      final collapsedTextHeight = (compact ? 16.0 : 18.0) * 1.2 * scale +
          4 +
          (compact ? 12.0 : 13.0) * 1.35 * scale +
          20 * scale +
          8 +
          (scale > 1 ? 28 * (scale - 1) : 0);
      final textBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.product.name,
            maxLines: showFull ? null : 1,
            overflow: showFull ? TextOverflow.visible : TextOverflow.ellipsis,
            style: titleStyle,
          ),
          const SizedBox(height: 4),
          if (showFull || preview.isNotEmpty)
            Text(
              showFull ? fullText : preview,
              maxLines: showFull ? null : 1,
              overflow: showFull ? TextOverflow.visible : TextOverflow.ellipsis,
              style: bodyStyle,
            ),
          if (canExpand)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: colors.secondary,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                showFull ? 'Ver menos' : 'Ver mais',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFull)
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: collapsedTextHeight),
              child: textBlock,
            )
          else
            SizedBox(
              height: collapsedTextHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textBlock,
                  const Spacer(),
                ],
              ),
            ),
          SizedBox(height: compact ? 8 : 10),
          _buildActionSection(context, compact: compact),
        ],
      );
    });
  }

  Widget _buildActionSection(BuildContext context, {required bool compact}) {
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
                    fontSize: compact ? 10 : 11,
                    color: colors.onSurfaceVariant)),
            Text(formatGiftPrice(widget.product.priceCents),
                style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primary)),
          ]),
      const SizedBox(height: 10),
      ElevatedButton(
          onPressed: widget.product.available ? widget.onGiftPressed : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12, vertical: compact ? 8 : 10),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (widget.product.available)
                  Icon(Icons.redeem, size: compact ? 16 : 18),
                Text(
                    widget.product.available
                        ? 'Presentear os Noivos'
                        : 'PRESENTEADO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: compact ? 11 : 12)),
              ])),
      const SizedBox(height: 8),
      Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Icon(Icons.chat_bubble_outline, size: 14, color: colors.secondary),
            Text('Inclui cartão de felicitações',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    color: colors.onSurfaceVariant)),
          ]),
    ]);
  }
}
