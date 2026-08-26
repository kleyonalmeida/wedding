import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CoupleSection extends StatelessWidget {
  const CoupleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 96.0, horizontal: 24.0),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'O Casal',
              style: AppTextStyles.cursive.copyWith(
                fontSize: MediaQuery.of(context).size.width >= 768 ? 80 : 52,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 64),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final double spacing = isMobile ? 16 : 48;
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Profile(
                    name: 'Kleyon',
                    imagePath: 'assets/images/noivo.png',
                    isMobile: isMobile,
                  ),
                  SizedBox(width: spacing),
                  Text(
                    '♥',
                    style: TextStyle(
                      fontSize: isMobile ? 32 : 48,
                      color: const Color(0xFF8C7362),
                      fontFamily: 'Playfair Display',
                    ),
                  ),
                  SizedBox(width: spacing),
                  _Profile(
                    name: 'Liandra',
                    imagePath: 'assets/images/noiva.png',
                    isMobile: isMobile,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 64),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672),
            child: Column(
              children: [
                Text(
                  '"Vamos nos casar!"',
                  style: AppTextStyles.serif.copyWith(
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nossa história começou com um simples encontro que floresceu em uma jornada inesquecível de cumplicidade e amor. Cada passo que demos juntos nos trouxe a este momento sublime onde decidimos unir nossas vidas para sempre.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sans.copyWith(
                    fontSize: 16,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
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

class _Profile extends StatelessWidget {
  final String name;
  final String imagePath;
  final bool isMobile;

  const _Profile({required this.name, required this.imagePath, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final double size = isMobile ? 110 : 200;
    
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: isMobile ? 4 : 8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 24),
        Text(
          name,
          style: AppTextStyles.serif.copyWith(
            fontSize: isMobile ? 18 : 24,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
