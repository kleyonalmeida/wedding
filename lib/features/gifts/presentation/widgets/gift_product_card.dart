import 'dart:math' as math;

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

class _TextMeasurementCacheKey {
  final String text;
  final TextStyle style;
  final double maxWidth;
  final int lines;
  final TextScaler textScaler;
  final TextDirection direction;
  final Locale? locale;

  _TextMeasurementCacheKey(this.text, this.style, this.maxWidth, this.lines,
      this.textScaler, this.direction, this.locale);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TextMeasurementCacheKey &&
        other.text == text &&
        other.style == style &&
        other.maxWidth == maxWidth &&
        other.lines == lines &&
        other.textScaler == textScaler &&
        other.direction == direction &&
        other.locale == locale;
  }

  @override
  int get hashCode =>
      Object.hash(text, style, maxWidth, lines, textScaler, direction, locale);
}

final _textMeasurementCache = <_TextMeasurementCacheKey, bool>{};

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
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final locale = Localizations.maybeLocaleOf(context);

    final key = _TextMeasurementCacheKey(
        text, style, maxWidth, lines, textScaler, direction, locale);
    if (_textMeasurementCache.containsKey(key)) {
      return _textMeasurementCache[key]!;
    }

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: lines,
      textDirection: direction,
      textScaler: textScaler,
      locale: locale,
    )..layout(maxWidth: maxWidth);

    final result = painter.didExceedMaxLines;
    if (_textMeasurementCache.length > 1000) {
      _textMeasurementCache.clear();
    }
    _textMeasurementCache[key] = result;
    return result;
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
        child: GestureDetector(
          onTap: () => _showProductDetailsModal(context),
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
        ),
      );
      return card;
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
          child: LayoutBuilder(builder: (context, constraints) {
            Widget content = widget.product.imageUrl.isEmpty
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
                  );
            if (!widget.product.available) {
              content = ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
                child: content,
              );
            }
            return content;
          }),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                )),
          ),
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
    final inherited = DefaultTextStyle.of(context).style;
    final titleColor = widget.product.available
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.5);
    final bodyColor = widget.product.available
        ? colors.onSurfaceVariant
        : colors.onSurfaceVariant.withValues(alpha: 0.5);

    final titleStyle = inherited.merge(TextStyle(
      fontFamily: 'Playfair Display',
      fontSize: compact ? 16 : 18,
      height: 1.2,
      color: titleColor,
    ));
    final bodyStyle = inherited.merge(TextStyle(
      fontSize: compact ? 12 : 13,
      height: 1.35,
      color: bodyColor,
    ));

    return LayoutBuilder(builder: (context, constraints) {
      final measureWidth = math.max(0.0, constraints.maxWidth - 1);
      final titleOverflows =
          _exceedsLines(widget.product.name, titleStyle, measureWidth, 1);
      final previewOverflows =
          _exceedsLines(preview, bodyStyle, measureWidth, 1);
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
                    color: widget.product.available
                        ? colors.primary
                        : colors.primary.withValues(alpha: 0.5))),
          ]),
      SizedBox(height: compact ? 8 : 10),
      ElevatedButton(
          onPressed: widget.product.available ? widget.onGiftPressed : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12, vertical: compact ? 6 : 10),
              minimumSize: Size(0, compact ? 32 : 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.product.available) ...[
                  Icon(Icons.redeem, size: compact ? 14 : 18),
                  const SizedBox(width: 6),
                ],
                Text(
                    widget.product.available
                        ? 'Presentear os Noivos'
                        : 'PRESENTEADO',
                    maxLines: 1,
                    style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: compact ? 12 : 13)),
              ]))),
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

  void _showProductDetailsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 320,
                        width: double.infinity,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : AppColors.surfaceContainerLow,
                        child: widget.product.imageUrl.isEmpty
                            ? const Center(child: Icon(Icons.image_not_supported_outlined, size: 64))
                            : InteractiveViewer(
                                child: Image.network(
                                  widget.product.imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatGiftPrice(widget.product.priceCents),
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (widget.product.description?.isNotEmpty == true) ...[
                          Text(
                            widget.product.description!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
                          ),
                          const SizedBox(height: 32),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.redeem),
                            onPressed: widget.product.available
                                ? () {
                                    Navigator.of(context).pop();
                                    widget.onGiftPressed();
                                  }
                                : null,
                            label: Text(
                              widget.product.available ? 'Presentear os Noivos' : 'PRESENTEADO',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
