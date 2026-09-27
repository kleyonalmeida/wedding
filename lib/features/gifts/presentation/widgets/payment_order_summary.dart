import 'package:flutter/material.dart';
import 'gift_price.dart';
import 'payment_return_status.dart';
import '../../data/models/payment_return_order.dart';

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

  String _date(DateTime date) {
    final d = date.toLocal();
    final offset = d.timeZoneOffset;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} às ${two(d.hour)}:${two(d.minute)} (UTC${offset.isNegative ? '-' : '+'}${two(offset.inMinutes.abs() ~/ 60)}:${two(offset.inMinutes.abs() % 60)})';
  }

  String _method(String? method) => switch (method) {
        'PIX' => 'PIX',
        'CREDIT_CARD' => 'Cartão de crédito',
        'DEBIT_CARD' => 'Cartão de débito',
        'BOLETO' => 'Boleto bancário',
        'TRANSFER' => 'Transferência',
        'DEPOSIT' => 'Depósito',
        null || '' => 'Ainda não informado',
        _ => 'Outra forma de pagamento',
      };
  String _money(int cents) => widget.order!.currency == 'BRL'
      ? formatGiftPrice(cents)
      : '${widget.order!.currency} ${(cents / 100).toStringAsFixed(2)}';
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    if (order == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(4)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final item
                in order.items.skip(_page * _pageSize).take(_pageSize))
              Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: LayoutBuilder(builder: (context, c) {
                    final compact = c.maxWidth < 280 ||
                        MediaQuery.textScalerOf(context).scale(16) > 24;
                    final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.quantity} × ${item.name}',
                              style: TextStyle(
                                  fontFamily: 'Bodoni Moda',
                                  fontSize: 20,
                                  height: 1.25,
                                  color: colors.onSurface)),
                          const SizedBox(height: 6),
                          Text('${_money(item.unitPriceCents)} por unidade',
                              style: TextStyle(color: colors.onSurfaceVariant)),
                          Text(
                              'Subtotal: ${_money(item.unitPriceCents * item.quantity)}',
                              style: TextStyle(color: colors.onSurface)),
                        ]);
                    final icon = Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8)),
                        child:
                            Icon(Icons.card_giftcard, color: colors.primary));
                    return compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                icon,
                                const SizedBox(height: 12),
                                details
                              ])
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                icon,
                                const SizedBox(width: 16),
                                Expanded(child: details)
                              ]);
                  })),
            if (order.items.length > _pageSize) ...[
              Text(
                  'Itens ${_page * _pageSize + 1}–${((_page + 1) * _pageSize).clamp(0, order.items.length)} de ${order.items.length}'),
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
            const Divider(),
            const SizedBox(height: 16),
            Text('TOTAL DO PEDIDO',
                style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: colors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(_money(order.totalCents),
                style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 24,
                    color: colors.primary)),
          ])),
      const SizedBox(height: 24),
      LayoutBuilder(builder: (context, c) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final columns = c.maxWidth >= 684 && scale <= 1.2
            ? 4
            : c.maxWidth >= 344 && scale <= 1.5
                ? 2
                : 1;
        final width = (c.maxWidth - 24 * (columns - 1)) / columns;
        Widget field(String label, String value) => SizedBox(
            width: width,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      letterSpacing: 1,
                      color: colors.onSurfaceVariant)),
              const SizedBox(height: 6),
              SelectableText(value,
                  style: TextStyle(fontSize: 14, color: colors.onSurface))
            ]));
        return Wrap(spacing: 24, runSpacing: 24, children: [
          field('CÓDIGO DO PEDIDO', order.id),
          field('FORMA DE PAGAMENTO', _method(order.paymentMethod)),
          field('PEDIDO CRIADO EM', _date(order.createdAtUtc)),
          field(
              'SITUAÇÃO DO PAGAMENTO', paymentReturnStatus(order.status).badge),
        ]);
      }),
      if (order.receivedAtUtc != null || order.confirmedAtUtc != null) ...[
        const SizedBox(height: 20),
        Text(
            order.receivedAtUtc != null
                ? 'Pagamento recebido em ${_date(order.receivedAtUtc!)}'
                : 'Pagamento confirmado em ${_date(order.confirmedAtUtc!)}',
            style: TextStyle(color: colors.onSurfaceVariant)),
      ],
      if (order.message?.trim().isNotEmpty == true) ...[
        const SizedBox(height: 32),
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.format_quote, color: colors.secondary),
              const SizedBox(height: 8),
              Text('DEDICATÓRIA DE ${order.senderName}',
                  style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: colors.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(order.message!,
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: colors.onSurface)),
            ])),
      ],
    ]);
  }
}
