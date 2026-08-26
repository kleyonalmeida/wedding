import 'package:flutter/material.dart';
import 'textured_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class Godparent {
  final String role;
  final String imageUrl;

  Godparent({required this.role, required this.imageUrl});
}

class GodparentsSection extends StatelessWidget {
  GodparentsSection({super.key});

  final List<Godparent> godparents = [
    Godparent(
      role: 'Madrinha',
      imageUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=800&q=80',
    ),
    Godparent(
      role: 'Padrinho',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
    ),
    Godparent(
      role: 'Madrinha',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    ),
    Godparent(
      role: 'Padrinho',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 96.0, horizontal: 24.0),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Padrinhos',
                style: AppTextStyles.cursive.copyWith(
                  fontSize: MediaQuery.of(context).size.width >= 768 ? 80 : 52,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AOS NOSSOS QUERIDOS PADRINHOS E MADRINHAS...',
              style: AppTextStyles.sans.copyWith(
                fontSize: 12,
                letterSpacing: 2.0,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const SizedBox(height: 80),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth >= 768 ? 4 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 48.0,
                    mainAxisSpacing: 48.0,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: godparents.length,
                  itemBuilder: (context, index) {
                    final godparent = godparents[index];
                    return Column(
                      children: [
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  godparent.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/images/hero.jpeg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          godparent.role,
                          style: AppTextStyles.serif.copyWith(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
