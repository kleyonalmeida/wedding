import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/cart_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutDialog extends StatefulWidget {
  final CartController cartController;
  final VoidCallback onBack;

  const CheckoutDialog({
    super.key,
    required this.cartController,
    required this.onBack,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _hasError = false;

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void _submit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _hasError = false;
    });

    final name = _nameController.text.trim();
    final message = _messageController.text.trim();
    final total = _formatCurrency(widget.cartController.totalValue);
    
    final StringBuffer itemsBuffer = StringBuffer();
    for (var item in widget.cartController.items) {
      itemsBuffer.writeln('- ${item.quantity}x ${item.product.name} (${_formatCurrency(item.product.currentPrice * item.quantity)})');
    }

    final text = 'Olá! Gostaria de presentear os noivos.\n\n'
        '*De:* $name\n'
        '${message.isNotEmpty ? '*Mensagem:* $message\n\n' : '\n'}'
        '*Presentes escolhidos:*\n$itemsBuffer\n'
        '*Total:* $total';

    // O telefone deve ser substituído pelo telefone real dos noivos (com DDI e DDD)
    // Exemplo: 5511999999999
    final whatsappUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
      if (mounted) {
        widget.cartController.clear();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirecionando para o WhatsApp... Obrigado pelo presente!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumo da sua compra',
                  style: AppTextStyles.serif.copyWith(
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _formatCurrency(item.product.currentPrice * item.quantity),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              _formatCurrency(widget.cartController.totalValue),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.grey, size: 28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('COMPRA', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, height: 1)),
                Text('SEGURA', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, height: 1.2)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: widget.onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                side: BorderSide(color: Colors.grey.shade400),
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text('Voltar para o carrinho', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 0,
              ),
              child: const Text(
                'Concluir compra',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
