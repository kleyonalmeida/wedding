import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'cover_flow_carousel.dart';

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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 96),
          CoverFlowCarousel(
            items: const [
              CarouselItem(imagePath: 'assets/images/_MG_1085.jpg'),
              CarouselItem(imagePath: 'assets/images/_MG_1064.jpg'),
              CarouselItem(imagePath: 'assets/images/_MG_1152.jpg'),
              CarouselItem(imagePath: 'assets/images/_MG_1229.jpg'),
              CarouselItem(imagePath: 'assets/images/_MG_1248.jpg'),
              CarouselItem(imagePath: 'assets/images/_MG_1288.jpg'),
              CarouselItem(imagePath: 'assets/images/_MG_1304.jpg'),
              CarouselItem(imagePath: 'assets/images/_MG_1333.jpg'),
              CarouselItem(imagePath: 'assets/images/_MG_1337.jpg'),
              CarouselItem(imagePath: 'assets/images/_MG_1341.jpg'),
            ],
            height: 420,
            initialPage: 3, // Inicia no _MG_1229.jpg
          ),
        ],
      ),
    );
  }
}
