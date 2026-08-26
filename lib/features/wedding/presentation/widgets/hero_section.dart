import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCbTV5pYldy7v1C_yVER9kTyWSOWIPrjK6fBBjA1zIFpCLDiHcPkaCrAR97zOABlGduX9GBUun2sSSghAJRS0hfdXBThUy7IQWszuRauyH4xdJVW_T0WDRROWObX_MAzC_JzBB3q-aRcv5gkIG4Xv3n1FKCeq24d5PImP99FMwUAwOysF4Qb-gNHnXh0ng-XS1nKvso6oV0DXmoMydS8dH40LrJAcfYDdhRo07UfWCE2R4g6PLNsEleeYy4NP72_NQ6Lw',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(76), // ~0.3 opacity
                  Colors.black.withAlpha(127), // ~0.5 opacity
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Save the date',
                  style: AppTextStyles.cursive.copyWith(
                    fontSize: 48,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'KLEYON & LIANDRA',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.serif.copyWith(
                    fontSize: 40, // Should be responsive
                    color: AppColors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '26.12.2026',
                  style: AppTextStyles.sans.copyWith(
                    fontSize: 20,
                    color: AppColors.white,
                    letterSpacing: 4.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: 64,
                  height: 1,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 32),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(
                    '"Para que todos vejam, e saibam, e considerem, e juntamente entendam que a mão do Senhor fez isso..."\nIsaías 41:20',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sans.copyWith(
                      color: AppColors.white.withAlpha(204), // ~0.8 opacity
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
