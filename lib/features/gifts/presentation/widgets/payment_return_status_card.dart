import 'package:flutter/material.dart';
import '../controllers/payment_return_controller.dart';
import 'payment_order_summary.dart';
import 'payment_return_help.dart';
import 'payment_return_actions.dart';
import 'payment_return_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentReturnStatusCard extends StatelessWidget {
  final PaymentReturnController controller;
  final String? whatsappNumber;
  const PaymentReturnStatusCard(
      {super.key, required this.controller, this.whatsappNumber});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 768;
    final status = paymentReturnStatus(controller.order?.status ?? '');
    final state = controller.state;
    final loading = state == PaymentReturnState.loading;
    final valid = state == PaymentReturnState.success;

    final badge = valid
        ? status.badge
        : switch (state) {
            PaymentReturnState.invalidLink => 'LINK INCOMPLETO OU INVÁLIDO',
            PaymentReturnState.inaccessible => 'PRESENTE INDISPONÍVEL',
            _ => 'CONSULTA INDISPONÍVEL',
          };

    final headline = valid
        ? status.headline
        : switch (state) {
            PaymentReturnState.loading => 'Consultando seu presente',
            PaymentReturnState.invalidLink =>
              'Confira o link do seu presente',
            PaymentReturnState.inaccessible =>
              'Não foi possível acessar este presente',
            _ => 'A consulta está indisponível',
          };

    final description = valid
        ? status.description
        : switch (state) {
            PaymentReturnState.loading =>
              'Aguarde enquanto consultamos as informações.',
            PaymentReturnState.invalidLink =>
              'O link está incompleto ou é inválido. Solicite ajuda aos noivos.',
            _ => controller.errorMessage ?? 'Tente novamente mais tarde.',
          };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.06),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Faixa decorativa no topo (degradê)
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryContainer,
                    AppColors.secondary,
                    AppColors.outlineVariant,
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(mobile ? 28 : 52),
              child: Column(
                children: [
                  // Ícone de status
                  if (!loading) ...[
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          colors.primary.withValues(alpha: 0.12),
                          colors.surface,
                        ]),
                      ),
                      child: Center(
                        child: Icon(
                          valid ? status.icon : Icons.info_outline_rounded,
                          size: 34,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Badge editorial
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: valid
                                ? AppColors.secondary
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              badge,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.sans.copyWith(
                                fontSize: 11,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Título principal
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: mobile ? 30 : 44,
                        height: mobile ? 1.3 : 1.2,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Descrição
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sans.copyWith(
                        fontSize: 15,
                        height: 1.75,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Loading
                  if (loading) const CircularProgressIndicator(),

                  // Resumo do presente (itens + mensagem) — somente se confirmado
                  if (valid && controller.order != null) ...[
                    PaymentOrderSummary(order: controller.order),
                    const SizedBox(height: 32),
                  ],

                  // Divider antes do bloco de ajuda
                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  // Card de contato / WhatsApp
                  PaymentReturnHelp(
                    orderId: controller.order?.id,
                    whatsappNumber: whatsappNumber,
                  ),

                  const SizedBox(height: 28),

                  // Botões de ação: Voltar ao Início / Ver outros presentes
                  PaymentReturnActions(
                    showRefresh: state == PaymentReturnState.error ||
                        valid &&
                            (controller.errorMessage != null ||
                                !const [
                                  'Confirmed',
                                  'Received',
                                  'Cancelled',
                                  'Overdue',
                                  'Refunded',
                                  'Disputed'
                                ].contains(controller.order?.status)),
                    isRefreshing: controller.isLoading,
                    onRefresh: controller.loadOrder,
                  ),

                  // Frase poética ao final (somente para estados de sucesso)
                  if (valid) ...[
                    const SizedBox(height: 32),
                    const Divider(height: 1),
                    const SizedBox(height: 28),
                    Text(
                      '"O amor não se mede pelo que se tem, mas pelo que se compartilha com quem se ama."',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cursive.copyWith(
                        fontSize: 16,
                        color: colors.primary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kleyon & Liandra • 26 . 12 . 2026',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sans.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
