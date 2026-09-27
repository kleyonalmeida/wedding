import 'package:flutter/material.dart';

class GiftsHeroSection extends StatefulWidget {
  const GiftsHeroSection({super.key});

  @override
  State<GiftsHeroSection> createState() => _GiftsHeroSectionState();
}

class _GiftsHeroSectionState extends State<GiftsHeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Start after reading the platform movement preference.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 768;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 32 : 56,
                  vertical: isSmallScreen ? 32 : 56,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, // 'fundo claro'
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Floral decorations via CustomPainter
                    Positioned(
                      top: -24,
                      right: -24,
                      child: CustomPaint(
                        size: const Size(160, 160),
                        painter: _FloralPainter(),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: CustomPaint(
                        size: const Size(160, 160),
                        painter: _FloralPainter(flip: true),
                      ),
                    ),

                    // Main content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Com Muito Amor & Gratidão',
                          style: theme.textTheme.labelLarge?.copyWith(
                            letterSpacing: 2,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lista de Presentes & Memórias',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: 'Playfair Display',
                            fontSize: isSmallScreen ? 32 : 48,
                            height: isSmallScreen ? 40 / 32 : 56 / 48,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'A sua presença na celebração da nossa união é o maior presente que poderíamos receber. Caso deseje nos homenagear de forma especial, preparamos com carinho esta lista de experiências e mimos que transformarão o início da nossa jornada em memórias inesquecíveis.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontFamily: 'Work Sans',
                            fontSize: 16,
                            height: 28 / 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: const [
                            _InfoBadge(
                                text: 'Experiências Reais',
                                subtitle: 'Momentos da lua de mel e afeto',
                                icon: Icons.favorite),
                            _InfoBadge(
                                text: 'Contribuição Afetiva',
                                subtitle: 'Seguro, simples e com dedicatória',
                                icon: Icons.volunteer_activism),
                            _InfoBadge(
                                text: 'Recado aos Noivos',
                                subtitle: 'Uma mensagem de carinho',
                                icon: Icons.mail_outline),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String text;
  final String subtitle;
  final IconData icon;
  const _InfoBadge(
      {required this.text, required this.subtitle, required this.icon});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(4)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 24, color: colors.secondary),
            const SizedBox(width: 12),
            Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(text,
                      style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: colors.secondary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 14)),
                ])),
          ]),
        ));
  }
}

// Simple floral painter for subtle decoration
class _FloralPainter extends CustomPainter {
  final bool flip;

  _FloralPainter({this.flip = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();

    if (flip) {
      canvas.translate(size.width, size.height);
      canvas.scale(-1, -1);
    }

    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width * 0.8,
      0,
    );
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.7,
      size.width,
      size.height * 0.2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
