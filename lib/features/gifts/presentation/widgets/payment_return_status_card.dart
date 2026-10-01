import 'package:flutter/material.dart';
import '../controllers/payment_return_controller.dart';
import 'payment_order_summary.dart';
import 'payment_return_help.dart';
import 'payment_return_actions.dart';
import 'payment_return_status.dart';

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
            PaymentReturnState.invalidLink => 'Confira o link do seu presente',
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
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: colors.primary.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ]),
          child: Stack(children: [
            Positioned.fill(
                child: IgnorePointer(
                    child: Container(
                        margin: EdgeInsets.all(mobile ? 8 : 12),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  colors.primary.withValues(alpha: 0.06),
                                  Colors.transparent,
                                  colors.primary.withValues(alpha: 0.02)
                                ]))))),
            Padding(
                padding: EdgeInsets.all(mobile ? 32 : 56),
                child: Column(children: [
                  if (!loading) ...[
                    Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              colors.primary.withValues(alpha: 0.12),
                              colors.surface
                            ])),
                        child: Center(
                            child: Icon(
                                valid ? status.icon : Icons.info_outline,
                                size: 32,
                                color: colors.primary))),
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.circle, size: 8, color: colors.secondary),
                          const SizedBox(width: 8),
                          Flexible(
                              child: Text(badge,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      height: 1.4,
                                      letterSpacing: 1.2,
                                      color: colors.onSurface)))
                        ])),
                    const SizedBox(height: 16),
                  ],
                  Semantics(
                      liveRegion: true,
                      child: Text(headline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: mobile ? 32 : 48,
                              height: mobile ? 1.25 : 1.17,
                              color: colors.onSurface))),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 512),
                      child: Text(description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              height: 1.75,
                              color: colors.onSurfaceVariant))),
                  const SizedBox(height: 40),
                  if (loading) const CircularProgressIndicator(),
                  if (valid && controller.order != null)
                    PaymentOrderSummary(order: controller.order),
                  if (valid && controller.errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Semantics(
                        liveRegion: true,
                        child: Text(controller.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.onSurfaceVariant)))
                  ],
                  const SizedBox(height: 32),
                  PaymentReturnHelp(
                      orderId: controller.order?.id,
                      whatsappNumber: whatsappNumber),
                  const SizedBox(height: 32),
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
                      onRefresh: controller.loadOrder),
                ])),
          ]),
        ));
  }
}
