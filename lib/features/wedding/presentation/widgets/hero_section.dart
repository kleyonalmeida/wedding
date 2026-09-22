import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HeroSection extends StatelessWidget {
  /// ScrollController da página para sincronizar a posição do fundo (Parallax).
  final ScrollController? scrollController;

  const HeroSection({super.key, this.scrollController});

  static const double _desktopParallaxFactor = 0.22;
  static const double _mobileParallaxFactor = 0.12;

  Widget _buildParallaxBackground(
    BuildContext context,
    double heroHeight,
    double parallaxFactor,
  ) {
    final double overflow = heroHeight * parallaxFactor;
    final double imageHeight = heroHeight * (1.0 + parallaxFactor);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetWidth =
        (MediaQuery.sizeOf(context).width * devicePixelRatio).round();

    return Positioned(
      top: -overflow,
      left: 0,
      right: 0,
      height: imageHeight,
      child: AnimatedBuilder(
        animation: scrollController ?? const _IdleListenable(),
        child: RepaintBoundary(
          child: Image.asset(
            'assets/images/hero-2880.webp',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            cacheWidth: targetWidth.clamp(640, 2560).toInt(),
            filterQuality: FilterQuality.medium,
          ),
        ),
        builder: (context, child) {
          final scrollOffset = scrollController?.hasClients == true
              ? scrollController!.offset
              : 0.0;
          final translation =
              (scrollOffset * parallaxFactor).clamp(0.0, overflow);
          return Transform.translate(
            offset: Offset(0, translation),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final parallaxFactor = MediaQuery.disableAnimationsOf(context)
        ? 0.0
        : isDesktop
            ? _desktopParallaxFactor
            : _mobileParallaxFactor;

    return ClipRect(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Camada de Fundo com Parallax Reativo de Alta Precisão ──────────
            _buildParallaxBackground(context, height, parallaxFactor),

            // ── Camada de Degradê para contraste do texto ─────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(76), // ~0.3 opacity
                    Colors.black.withAlpha(140), // ~0.55 opacity
                  ],
                ),
              ),
            ),

            // ── Conteúdo Central ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Save the date',
                    style: AppTextStyles.cursive.copyWith(
                      fontSize: isDesktop ? 84 : 56,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KLEYON & LIANDRA',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.serif.copyWith(
                      fontSize: 40,
                      color: AppColors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '26.12.2026',
                    style: AppTextStyles.sans.copyWith(
                      fontSize: 20,
                      color: AppColors.white,
                      letterSpacing: 4.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: 64,
                    height: 1,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 32),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Text(
                      '"Para que todos vejam, e saibam, e considerem, e juntamente entendam que a mão do Senhor fez isso..."\nIsaías 41:20',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sans.copyWith(
                        color: AppColors.white.withAlpha(204), // ~0.8 opacity
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),

                  // ── Indicador de Rolagem (Seta Animada) ───────────────────
                  const SizedBox(height: 48),
                  _ScrollIndicator(scrollController: scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleListenable implements Listenable {
  const _IdleListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

// ── Widget da Seta Animada ────────────────────────────────────────────────────
class _ScrollIndicator extends StatefulWidget {
  final ScrollController? scrollController;

  const _ScrollIndicator({required this.scrollController});

  @override
  State<_ScrollIndicator> createState() => _ScrollIndicatorState();
}

class _ScrollIndicatorState extends State<_ScrollIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bounceAnim;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _bounceAnim = Tween<double>(begin: 0, end: 18).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
    widget.scrollController?.addListener(_syncAnimation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.disableAnimationsOf(context);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _ScrollIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_syncAnimation);
      widget.scrollController?.addListener(_syncAnimation);
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    final controller = widget.scrollController;
    final isAtTop = controller == null ||
        !controller.hasClients ||
        controller.offset < 24.0;

    if (isAtTop && !_disableAnimations) {
      if (!_animController.isAnimating) {
        _animController.repeat(reverse: true);
      }
    } else if (_animController.isAnimating) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_syncAnimation);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _bounceAnim,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnim.value),
            child: child,
          );
        },
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.white.withAlpha(178),
          size: 32,
        ),
      ),
    );
  }
}
