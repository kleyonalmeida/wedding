import 'package:flutter/material.dart';
import 'package:wedding_app/app_navigation.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentReturnActions extends StatelessWidget {
  final bool showRefresh;
  final bool isRefreshing;
  final VoidCallback? onRefresh;

  const PaymentReturnActions({
    super.key,
    this.showRefresh = false,
    this.isRefreshing = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 640;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        // Voltar ao Início — botão primário (pill)
        SizedBox(
          width: isMobile ? double.infinity : null,
          child: ElevatedButton(
            onPressed: () => AppNavigation.replace(context, '/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              elevation: 2,
            ),
            child: Text(
              'VOLTAR AO INÍCIO',
              style: AppTextStyles.sans.copyWith(
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // Ver Outros Presentes — botão secundário (pill contornado)
        SizedBox(
          width: isMobile ? double.infinity : null,
          child: OutlinedButton(
            onPressed: () => AppNavigation.replace(context, '/presentes'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outlineVariant),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            ),
            child: Text(
              'VER OUTROS PRESENTES',
              style: AppTextStyles.sans.copyWith(
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // Atualizar (somente quando necessário, estilo discreto)
        if (showRefresh)
          SizedBox(
            width: isMobile ? double.infinity : null,
            child: TextButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'ATUALIZAR SITUAÇÃO',
                style: AppTextStyles.sans.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
