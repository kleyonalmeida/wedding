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
          Text(
            'O Casal',
            style: AppTextStyles.cursive.copyWith(
              fontSize: MediaQuery.of(context).size.width >= 768 ? 96 : 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 64),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Profile(
                      name: 'Kleyon',
                      imagePath: 'assets/images/noivo.png',
                    ),
                    SizedBox(width: 48),
                    Text(
                      '♥',
                      style: TextStyle(
                        fontSize: 48,
                        color: Color(0xFF8C7362),
                        fontFamily: 'Playfair Display',
                      ),
                    ),
                    SizedBox(width: 48),
                    _Profile(
                      name: 'Liandra',
                      imagePath: 'assets/images/noiva.png',
                    ),
                  ],
                );
              } else {
                return const Column(
                  children: [
                    _Profile(
                      name: 'Kleyon',
                      imagePath: 'assets/images/noivo.png',
                    ),
                    SizedBox(height: 32),
                    Text(
                      '♥',
                      style: TextStyle(
                        fontSize: 48,
                        color: Color(0xFF8C7362),
                        fontFamily: 'Playfair Display',
                      ),
                    ),
                    SizedBox(height: 32),
                    _Profile(
                      name: 'Liandra',
                      imagePath: 'assets/images/noiva.png',
                    ),
                  ],
                );
              }
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

  const _Profile({required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 8),
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
        const SizedBox(height: 24),
        Text(
          name,
          style: AppTextStyles.serif.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
