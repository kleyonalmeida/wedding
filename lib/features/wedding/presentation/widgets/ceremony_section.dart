import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'mapa_casamento_widget.dart';

// Coordenadas do local do evento
const double _lat = -8.054;
const double _lng = -34.881;
const String _locationName = 'Casa da Mangueira Eventos';

class CeremonySection extends StatelessWidget {
  const CeremonySection({super.key});

  void _showNavigationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _NavigationBottomSheet(),
    );
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Cerimônia',
                  style: AppTextStyles.cursive.copyWith(
                    fontSize:
                        MediaQuery.of(context).size.width >= 768 ? 80 : 52,
                    color: AppColors.primary,
                  ),
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
                      const Icon(Icons.map_outlined,
                          color: AppColors.primary, size: 20),
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
            blurRadius: 12,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.asset(
            'assets/images/ceremony-1600.webp',
            fit: BoxFit.cover,
            cacheWidth: 1200,
            filterQuality: FilterQuality.medium,
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
            blurRadius: 0,
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          if (showMapButton) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Builder(
                builder: (ctx) => ElevatedButton.icon(
                  onPressed: () => _showNavigationOptions(ctx),
                  icon: const Icon(Icons.near_me_outlined, size: 20),
                  label: const Text('COMO CHEGAR'),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet de seleção de app de navegação
// ---------------------------------------------------------------------------

class _NavigationBottomSheet extends StatelessWidget {
  const _NavigationBottomSheet();

  Future<void> _launchNavigation(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Não foi possível abrir o app de navegação.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Não foi possível abrir o app de navegação.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1A18) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle visual
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.near_me_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como chegar',
                        style: AppTextStyles.serif.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        _locationName,
                        style: AppTextStyles.sans.copyWith(
                          fontSize: 12,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Waze
              _NavOption(
                icon: _WazeLogo(),
                label: 'Waze',
                description: 'Navegação com trânsito em tempo real',
                onTap: () {
                  Navigator.pop(context);
                  _launchNavigation(
                    'waze://?ll=$_lat,$_lng&navigate=yes',
                    context,
                  );
                },
              ),
              const SizedBox(height: 12),
              // Google Maps
              _NavOption(
                icon: _GoogleMapsLogo(),
                label: 'Google Maps',
                description: 'Abrir no Google Maps',
                onTap: () {
                  Navigator.pop(context);
                  _launchNavigation(
                    'https://www.google.com/maps/dir/?api=1'
                    '&destination=$_lat,$_lng'
                    '&destination_place_id=ChIJa4bpNrlD1BQR6EkNChDuZKg',
                    context,
                  );
                },
              ),
              const SizedBox(height: 12),
              // Maps padrão (Apple Maps / navegador)
              _NavOption(
                icon: const Icon(Icons.map_rounded,
                    color: Color(0xFF3478F6), size: 30),
                label: 'Maps (Apple / Padrão)',
                description: 'Abrir no app de mapas padrão',
                onTap: () {
                  Navigator.pop(context);
                  _launchNavigation(
                    'https://maps.apple.com/?daddr=$_lat,$_lng&dirflg=d',
                    context,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Opção individual de navegação
// ---------------------------------------------------------------------------

class _NavOption extends StatelessWidget {
  const _NavOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? AppColors.onPrimaryContainer.withAlpha(60)
          : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(width: 40, height: 40, child: Center(child: icon)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.sans.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTextStyles.sans.copyWith(
                        fontSize: 12,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.outline, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logos dos apps
// ---------------------------------------------------------------------------

class _WazeLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF33CCFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.directions_car_rounded,
          color: Colors.white, size: 18),
    );
  }
}

class _GoogleMapsLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.location_on_rounded,
          color: Colors.white, size: 18),
    );
  }
}
