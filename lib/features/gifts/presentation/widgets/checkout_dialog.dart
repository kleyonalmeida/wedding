import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/cart_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/payment_repository.dart';
import '../../../../core/network/api_client.dart';
import 'gift_price.dart';
import 'gift_dedication_modal.dart';

class CheckoutDialog extends StatefulWidget {
  final CartController cartController;
  final VoidCallback onBack;
  final VoidCallback? onCatalogChanged;
  final VoidCallback? onAddToCart;

  const CheckoutDialog({
    super.key,
    required this.cartController,
    required this.onBack,
    this.onCatalogChanged,
    this.onAddToCart,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  void _submit() async {
    if (_isLoading) return;
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final message = _messageController.text.trim();
    final items = widget.cartController.items
        .map((e) => {
              'giftId': e.product.id,
              'quantity': e.quantity,
            })
        .toList();

    try {
      final checkoutUrl = await _paymentRepository.createGiftOrder(
        senderName: name,
        message: message,
        items: items,
      );

      if (checkoutUrl != null && mounted) {
        final uri = Uri.parse(checkoutUrl);
        if (uri.scheme == 'https' &&
            (uri.host == 'asaas.com' || uri.host.endsWith('.asaas.com')) &&
            await canLaunchUrl(uri)) {
          final launched = await launchUrl(uri, webOnlyWindowName: '_self');
          if (launched && mounted) {
            widget.cartController.clear();
            Navigator.of(context).pop();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    "Não foi possível abrir o pagamento. Tente novamente.")));
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Não foi possível abrir o pagamento. Tente novamente.')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Falha ao processar o pedido. Tente novamente.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 409) widget.onCatalogChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.statusCode == 409
                  ? 'Presente esgotado ou pedido em análise. A lista foi atualizada.'
                  : e.statusCode == 502
                      ? 'Este pedido precisa ser conferido antes de uma nova tentativa. Entre em contato com os noivos.'
                      : 'Não foi possível iniciar o pagamento. Tente novamente.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Não foi possível confirmar o pedido. Confira com os noivos antes de tentar novamente.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    _paymentRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GiftDedicationModal(
      itemTitle: widget.cartController.items.length == 1
          ? widget.cartController.items.first.product.name
          : 'Seus presentes',
      itemValue: formatGiftPrice(widget.cartController.totalCents),
      isCustomAmount: false,
      isLoading: _isLoading,
      onClose: widget.onBack,
      onAddToCart: widget.onAddToCart,
      summary: _buildSummarySection(context),
      onConfirm: (name, message, _) {
        _nameController.text = name;
        _messageController.text = message;
        _submit();
      },
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.cartController.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity > 1 ? '${item.quantity}x ' : ''}${item.product.name}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatGiftPrice(item.product.priceCents * item.quantity),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }),
        ...widget.cartController.items
            .where((item) =>
                (item.product.fullDescription ?? item.product.description)
                    ?.isNotEmpty ==
                true)
            .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(item.product.fullDescription ??
                    item.product.description!))),
        const SizedBox(height: 8),
        Divider(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              formatGiftPrice(widget.cartController.totalCents),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
