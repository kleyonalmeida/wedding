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
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        if (showRefresh)
          SizedBox(
            width: isMobile ? double.infinity : null,
            child: ElevatedButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.surfaceContainerLow,
                foregroundColor: colors.onSurface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              label: Text(
                'ATUALIZAR SITUAÇÃO',
                style: AppTextStyles.sans.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        SizedBox(
          width: isMobile ? double.infinity : null,
          child: ElevatedButton(
            onPressed: () => AppNavigation.replace(context, '/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'VOLTAR AO INÍCIO',
              style: AppTextStyles.sans.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(
          width: isMobile ? double.infinity : null,
          child: ElevatedButton(
            onPressed: () => AppNavigation.replace(context, '/presentes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.surfaceContainerLow,
              foregroundColor: colors.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'VER OUTROS PRESENTES',
              style: AppTextStyles.sans.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
