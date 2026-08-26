import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'mapa_casamento_widget.dart';

class CeremonySection extends StatelessWidget {
  const CeremonySection({super.key});

  Future<void> _openMap() async {
    final Uri url = Uri.parse('https://share.google/0Zp6f0NKpPhjc4ajj');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 96.0, horizontal: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1152),
          child: Column(
            children: [
              Text(
                'Cerimônia',
                style: AppTextStyles.cursive.copyWith(
                  fontSize: MediaQuery.of(context).size.width >= 768 ? 96 : 64,
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
                                context,
                                icon: Icons.access_time_rounded,
                                title: 'Data e Horário',
                                subtitle: 'Sábado, 26 de Dezembro de 2026',
                                highlight: 'às 15:30 horas',
                              ),
                              const SizedBox(height: 24),
                              _buildCard(
                                context,
                                icon: Icons.location_on_rounded,
                                title: 'Localização',
                                subtitle: 'Casa da Mangueira Eventos',
                                highlight: 'Local da Cerimônia & Recepção',
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
                          context,
                          icon: Icons.access_time_rounded,
                          title: 'Data e Horário',
                          subtitle: 'Sábado, 26 de Dezembro de 2026',
                          highlight: 'às 15:30 horas',
                        ),
                        const SizedBox(height: 24),
                        _buildCard(
                          context,
                          icon: Icons.location_on_rounded,
                          title: 'Localização',
                          subtitle: 'Casa da Mangueira Eventos',
                          highlight: 'Local da Cerimônia & Recepção',
                          showMapButton: true,
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 56),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.map_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'MAPA INTERATIVO',
                        style: AppTextStyles.sans.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const MapaCasamentoWidget(),
                ],
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String highlight,
    bool showMapButton = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 5.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: AppTextStyles.serif.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: AppTextStyles.sans.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            highlight,
            style: AppTextStyles.sans.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          if (showMapButton) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.directions_outlined, size: 20),
                label: const Text('ABRIR NO GOOGLE MAPS'),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
