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
      duration: const Duration(milliseconds: 800),
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

    _controller.forward();
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 32 : 56,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, // 'fundo claro'
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Floral decorations via CustomPainter
                    Positioned(
                      top: 0,
                      left: 0,
                      child: CustomPaint(
                        size: const Size(64, 64),
                        painter: _FloralPainter(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CustomPaint(
                        size: const Size(64, 64),
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
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Agradecemos de coração por fazerem parte desta nova etapa das nossas vidas. '
                          'Aqui, vocês podem escolher como nos presentear e deixar um recado especial para nós!',
                          style: theme.textTheme.bodyLarge?.copyWith(
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
                            _InfoBadge(text: 'Experiências Reais', icon: Icons.flight_takeoff),
                            _InfoBadge(text: 'Contribuição Afetiva', icon: Icons.favorite_border),
                            _InfoBadge(text: 'Recado aos Noivos', icon: Icons.mail_outline),
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
  final IconData icon;

  const _InfoBadge({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple floral painter for subtle decoration
class _FloralPainter extends CustomPainter {
  final bool flip;
  
  _FloralPainter({this.flip = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    
    if (flip) {
      canvas.translate(size.width, size.height);
      canvas.scale(-1, -1);
    }

    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.5,
      size.width * 0.8, 0,
    );
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.4, size.height * 0.7,
      size.width, size.height * 0.2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
