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
      imageUrl: 'https://lh3.googleusercontent.com/aida/AEtjO1U0FJXQwNizB6g7QTGUA7mOhT8l4BAHeBU1N9KuywqWRUNYLsJiSTMAmXge6X8od2DF1m5zmi1jug_1cOoLziTUOqDnoLofB5yRRCHSSnST3uVL7QvmvxnmyPjc6bz41PlpmkNufoR0lHTI6-jpv7F_PtzjXSOR--8o89p4hGgWA2N0ijGLFA4e8TGVSX65GNgl3VIShYEYD6nORKRhN4qNF4uRzuN0h0BYRVX76h5NECk55gck9QhZdfw',
    ),
    Godparent(
      role: 'Padrinho',
      imageUrl: 'https://lh3.googleusercontent.com/aida/AEtjO1VOYzERucdhiGDI-RtVgJelfNoCoRaovurIO13A4ks6AuktlqsAmD5H6gqsF-Odm5m6ldwggN_JoSb9vbRU_TqV7Kgl5ZzBwyJP2EqL31EI-2qfyR7btXHmRLLYfcrVy7CczEZ1X3qc4Jel3eamLu6wC3RU-b5rDnoa0DUe1KK99Mv-2YegYBOD88xrGUFTtJCe87JW_P1zpj4kntcLEiAJzDeNtZTryixPSoCUOHTIWbumBtTguNI1SHw',
    ),
    Godparent(
      role: 'Madrinha',
      imageUrl: 'https://lh3.googleusercontent.com/aida/AEtjO1U0FJXQwNizB6g7QTGUA7mOhT8l4BAHeBU1N9KuywqWRUNYLsJiSTMAmXge6X8od2DF1m5zmi1jug_1cOoLziTUOqDnoLofB5yRRCHSSnST3uVL7QvmvxnmyPjc6bz41PlpmkNufoR0lHTI6-jpv7F_PtzjXSOR--8o89p4hGgWA2N0ijGLFA4e8TGVSX65GNgl3VIShYEYD6nORKRhN4qNF4uRzuN0h0BYRVX76h5NECk55gck9QhZdfw',
    ),
    Godparent(
      role: 'Padrinho',
      imageUrl: 'https://lh3.googleusercontent.com/aida/AEtjO1VOYzERucdhiGDI-RtVgJelfNoCoRaovurIO13A4ks6AuktlqsAmD5H6gqsF-Odm5m6ldwggN_JoSb9vbRU_TqV7Kgl5ZzBwyJP2EqL31EI-2qfyR7btXHmRLLYfcrVy7CczEZ1X3qc4Jel3eamLu6wC3RU-b5rDnoa0DUe1KK99Mv-2YegYBOD88xrGUFTtJCe87JW_P1zpj4kntcLEiAJzDeNtZTryixPSoCUOHTIWbumBtTguNI1SHw',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 96.0, horizontal: 24.0),
        child: Column(
          children: [
            Text(
              'Padrinhos',
              style: AppTextStyles.cursive.copyWith(
                fontSize: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AOS NOSSOS QUERIDOS PADRINHOS E MADRINHAS...',
              style: AppTextStyles.sans.copyWith(
                fontSize: 12,
                letterSpacing: 2.0,
                color: AppColors.dark.withAlpha(153), // ~0.6
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
                                border: Border.all(color: AppColors.white, width: 4),
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
                            color: AppColors.dark,
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
