import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentReturnHelp extends StatelessWidget {
  final String? orderId;
  final String? whatsappNumber;

  const PaymentReturnHelp({
    super.key,
    this.orderId,
    this.whatsappNumber,
  });

  Future<void> _launchWhatsApp(BuildContext context) async {
    if (!_validNumber) return;

    final message = orderId != null
        ? 'Olá, estou entrando em contato sobre a contribuição do presente #KL-$orderId.'
        : 'Olá, estou entrando em contato sobre a contribuição do presente.';

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$whatsappNumber?text=$encodedMessage');

    try {
      if (await canLaunchUrl(url)) {
        final opened =
            await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Não foi possível abrir o WhatsApp.')));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    }
  }

  bool get _validNumber =>
      RegExp(r'^[1-9][0-9]{9,14}$').hasMatch(whatsappNumber ?? '');

  @override
  Widget build(BuildContext context) {
    final hasWhatsApp = _validNumber;
    final colors = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                  ),
                  child:
                      Icon(Icons.info_outline, color: colors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precisa consultar a situação ou atualizar os dados?',
                        style: AppTextStyles.workSans.copyWith(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Se precisar de ajuda com esta contribuição, entre em contato diretamente com os noivos.',
                        style: AppTextStyles.workSans.copyWith(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasWhatsApp) ...[
            if (isMobile) const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _launchWhatsApp(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.onSurface,
                elevation: 1,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Text(
                'Falar no WhatsApp',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              label: const Icon(Icons.open_in_new, size: 16),
            ),
          ]
        ],
      ),
    );
  }
}
