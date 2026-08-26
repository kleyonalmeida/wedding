import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class WeddingFooter extends StatelessWidget {
  const WeddingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56.0, horizontal: 24.0),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Text(
            'K&L',
            style: AppTextStyles.serif.copyWith(
              fontSize: 36,
              letterSpacing: 4.0,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '© 2026 Kleyon & Liandra. Feito com amor.',
            textAlign: TextAlign.center,
            style: AppTextStyles.sans.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: onSurface.withOpacity(0.85),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
