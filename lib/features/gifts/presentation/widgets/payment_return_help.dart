import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
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

    const message =
        'Olá Kleyon & Liandra! Estou entrando em contato sobre o presente que enviei para vocês. 💛';

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
            const SnackBar(
                content: Text('Não foi possível abrir o WhatsApp.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível abrir o WhatsApp.')),
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
        color: colors.surfaceContainerLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
        ),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.support_agent_rounded,
                      color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dúvidas ou precisa falar conosco?',
                        style: AppTextStyles.workSans.copyWith(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nosso cerimonial está disponível para lhe auxiliar diretamente.',
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
            OutlinedButton.icon(
              onPressed: () => _launchWhatsApp(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF25D366),
                side: const BorderSide(color: Color(0xFF25D366)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: Text(
                'FALAR NO WHATSAPP',
                style: AppTextStyles.sans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
