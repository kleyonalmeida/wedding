import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class WeddingFooter extends StatelessWidget {
  const WeddingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      color: AppColors.surface,
      child: Column(
        children: [
          Text(
            'K&L',
            style: AppTextStyles.serif.copyWith(
              fontSize: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '© 2026 Kleyon & Liandra. Feito com amor.',
            style: AppTextStyles.sans.copyWith(
              fontSize: 10,
              letterSpacing: 2.0,
              color: AppColors.dark.withAlpha(102), // ~0.4 opacity
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
