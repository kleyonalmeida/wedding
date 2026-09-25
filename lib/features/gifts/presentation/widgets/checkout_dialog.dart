import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/cart_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/payment_repository.dart';
import '../../../../core/network/api_client.dart';
import 'gift_price.dart';

class CheckoutDialog extends StatefulWidget {
  final CartController cartController;
  final VoidCallback onBack;
  final VoidCallback? onCatalogChanged;

  const CheckoutDialog({
    super.key,
    required this.cartController,
    required this.onBack,
    this.onCatalogChanged,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _hasError = false;

  bool _isLoading = false;

  void _submit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _hasError = false;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: isMobile ? double.infinity : 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height - 32,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(
                    'Resumo da sua compra',
                    style: AppTextStyles.serif.copyWith(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  )),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (isMobile) ...[
                _buildSummarySection(context),
                const SizedBox(height: 32),
                _buildFormSection(context),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildSummarySection(context),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 6,
                      child: _buildFormSection(context),
                    ),
                  ],
                ),
              const SizedBox(height: 48),
              _buildFooter(context, isMobile),
            ],
          ),
        ),
      ),
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

  Widget _buildFormSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deixe sua mensagem de carinho',
          style: AppTextStyles.serif.copyWith(
            fontSize: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Insira seu nome',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '(Este será o nome assinado no cartão)',
          style: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: _hasError ? Colors.redAccent : AppColors.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: _hasError ? Colors.redAccent : AppColors.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: _hasError ? Colors.redAccent : AppColors.primary,
              ),
            ),
          ),
        ),
        if (_hasError)
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              'Informe seu nome para o casal',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Mensagem (Opcional)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile) {
    final secureLabel = Row(
      children: [
        const Icon(Icons.lock_outline, color: Colors.grey, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('COMPRA',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    height: 1)),
            Text('SEGURA',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    height: 1.2)),
          ],
        ),
      ],
    );
    final backButton = OutlinedButton(
      onPressed: widget.onBack,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: Colors.grey.shade400),
        foregroundColor: Colors.grey.shade700,
      ),
      child: const Text('Voltar para o carrinho',
          style: TextStyle(fontWeight: FontWeight.w600)),
    );
    final finishButton = ElevatedButton(
      onPressed: _isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Text(
              'Concluir compra',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          secureLabel,
          const SizedBox(height: 20),
          finishButton,
          const SizedBox(height: 8),
          backButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        secureLabel,
        Row(
          children: [backButton, const SizedBox(width: 12), finishButton],
        ),
      ],
    );
  }
}
