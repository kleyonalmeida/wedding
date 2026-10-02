import 'package:flutter/material.dart';
import 'gift_price.dart';
import '../../data/models/payment_return_order.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentOrderSummary extends StatefulWidget {
  final PaymentReturnOrder? order;
  const PaymentOrderSummary({super.key, this.order});
  @override
  State<PaymentOrderSummary> createState() => _PaymentOrderSummaryState();
}

class _PaymentOrderSummaryState extends State<PaymentOrderSummary> {
  int _page = 0;
  static const _pageSize = 10;

  @override
  void didUpdateWidget(covariant PaymentOrderSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order?.id != widget.order?.id ||
        _page * _pageSize >= (widget.order?.items.length ?? 0)) {
      _page = 0;
    }
  }

  String _money(int cents) => widget.order!.currency == 'BRL'
      ? formatGiftPrice(cents)
      : '${widget.order!.currency} ${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    if (order == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Card principal: itens + valor
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Itens do presente
          for (final item
              in order.items.skip(_page * _pageSize).take(_pageSize))
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: LayoutBuilder(builder: (context, c) {
                final compact = c.maxWidth < 280 ||
                    MediaQuery.textScalerOf(context).scale(16) > 24;

                final iconBox = Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(Icons.card_giftcard,
                      color: colors.primary, size: 28),
                );

                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ITEM ESCOLHIDO',
                      style: AppTextStyles.sans.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.quantity > 1 ? '${item.quantity} × ' : ''}${item.name}',
                      style: TextStyle(
                        fontFamily: 'Bodoni Moda',
                        fontSize: 22,
                        height: 1.25,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Valor destacado
                    Text(
                      'VALOR CONTRIBUÍDO',
                      style: AppTextStyles.sans.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _money(item.unitPriceCents * item.quantity),
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                );

                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          iconBox,
                          const SizedBox(height: 16),
                          details,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          iconBox,
                          const SizedBox(width: 20),
                          Expanded(child: details),
                        ],
                      );
              }),
            ),

          // Paginação (caso tenha muitos itens)
          if (order.items.length > _pageSize) ...[
            const Divider(height: 24),
            Wrap(spacing: 12, children: [
              TextButton(
                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  child: const Text('Itens anteriores')),
              TextButton(
                  onPressed: (_page + 1) * _pageSize < order.items.length
                      ? () => setState(() => _page++)
                      : null,
                  child: const Text('Próximos itens'))
            ]),
          ],
        ]),
      ),

      // Mensagem do convidado (condicional)
      if (order.message?.trim().isNotEmpty == true) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote_rounded,
                  color: colors.secondary, size: 28),
              const SizedBox(height: 10),
              Text(
                'MENSAGEM ENVIADA AOS NOIVOS',
                style: AppTextStyles.sans.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                order.message!,
                style: AppTextStyles.sans.copyWith(
                  fontSize: 15,
                  height: 1.7,
                  fontStyle: FontStyle.italic,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    ]);
  }
}
