import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentReturnHeading extends StatelessWidget {
  const PaymentReturnHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 768;
    return Column(children: [
      // Badge editorial
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CONFIRMAÇÃO DE HOMENAGEM',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      // Monograma K&L cursivo
      Text(
        'Kleyon & Liandra',
        textAlign: TextAlign.center,
        style: AppTextStyles.cursive.copyWith(
          fontSize: mobile ? 36 : 48,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 8),
      // Subtítulo
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Text(
          'A celebração da nossa união ganha ainda mais encanto com o seu carinho e presença.',
          textAlign: TextAlign.center,
          style: AppTextStyles.sans.copyWith(
            fontSize: 15,
            height: 1.75,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(height: 48),
    ]);
  }
}
