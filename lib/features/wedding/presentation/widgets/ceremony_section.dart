import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CeremonySection extends StatelessWidget {
  const CeremonySection({super.key});

  Future<void> _openMap() async {
    final Uri url = Uri.parse('https://maps.google.com/?q=-23.5617,-46.6588');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 96.0, horizontal: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1152), // max-w-6xl
          child: Column(
            children: [
              Text(
                'Cerimônia',
                style: AppTextStyles.cursive.copyWith(
                  fontSize: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 768) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildImage()),
                        const SizedBox(width: 48),
                        Expanded(
                          child: Column(
                            children: [
                              _buildCard(
                                title: 'Data e Horário',
                                description: 'Sábado, 26 de Dezembro de 2026 às 16:00 horas.',
                              ),
                              const SizedBox(height: 32),
                              _buildCard(
                                title: 'Localização',
                                description: 'Espaço Villa Real - Av. das Flores, 1234 - Jardim Botânico.',
                                showMapButton: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildImage(),
                        const SizedBox(height: 48),
                        _buildCard(
                          title: 'Data e Horário',
                          description: 'Sábado, 26 de Dezembro de 2026 às 16:00 horas.',
                        ),
                        const SizedBox(height: 32),
                        _buildCard(
                          title: 'Localização',
                          description: 'Espaço Villa Real - Av. das Flores, 1234 - Jardim Botânico.',
                          showMapButton: true,
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            'https://lh3.googleusercontent.com/aida/AEtjO1X3Icjz8TiRljPtYyp2brG1_mMGVFxFwsSmT10Hu8y94kTe0HqbSACGcthO6GlRBNdLugFryKvRkRAWWS8vuSu9QaZs3CxEhN9XKsT73exdL3bzNHdRSiDUCsAdOdXXJdd7m6yvHjcsH1uOQSC159w9hdXh1GjCXdaytiOCA3HjjcwDE2t61ibwrih6J9eVR8BPPrRfZbU00S0kUdwozr_3jjfMBwcRwxB1ZB7bTXQ_IiM3Pm87BrglWg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required String description, bool showMapButton = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.serif.copyWith(
              fontSize: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.sans.copyWith(
              fontSize: 16,
              color: AppColors.dark.withAlpha(178), // ~0.7
              height: 1.5,
            ),
          ),
          if (showMapButton) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('ABRIR NO MAPA'),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
