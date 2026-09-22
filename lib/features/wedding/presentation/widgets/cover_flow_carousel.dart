import 'dart:ui';
import 'package:flutter/material.dart';

class CarouselItem {
  final String imagePath;
  final String thumbnailPath;
  final String? title;

  const CarouselItem({
    required this.imagePath,
    required this.thumbnailPath,
    this.title,
  });
}

class CoverFlowCarousel extends StatefulWidget {
  final List<CarouselItem> items;
  final double height;
  final int initialPage;

  const CoverFlowCarousel({
    super.key,
    required this.items,
    this.height = 420.0,
    this.initialPage = 0,
  });

  @override
  State<CoverFlowCarousel> createState() => _CoverFlowCarouselState();
}

class _CoverFlowCarouselState extends State<CoverFlowCarousel> {
  late PageController _pageController;
  late double _currentPage;
  List<ImageProvider<Object>> _cardImageProviders = const [];
  bool _imagesReady = false;
  int? _cachedImageHeight;
  String? _cachedItemsSignature;
  int _precacheGeneration = 0;
  final int _loopOffset =
      10000; // Offset alto para permitir scroll infinito para a esquerda

  @override
  void initState() {
    super.initState();
    // Inicializa num índice gigante para permitir loop infinito em ambas direções
    final int startPage =
        (_loopOffset * widget.items.length) + widget.initialPage;
    _currentPage = startPage.toDouble();
    _pageController = PageController(
      initialPage: startPage,
      viewportFraction: 1.0,
    );
    _pageController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetHeight = (widget.height * devicePixelRatio * 1.25)
        .round()
        .clamp(720, 1600)
        .toInt();
    final itemsSignature =
        widget.items.map((item) => item.thumbnailPath).join('|');

    if (_cachedImageHeight == targetHeight &&
        _cachedItemsSignature == itemsSignature) {
      return;
    }

    _cachedImageHeight = targetHeight;
    _cachedItemsSignature = itemsSignature;
    _prepareImages(targetHeight);
  }

  Future<void> _prepareImages(int targetHeight) async {
    final generation = ++_precacheGeneration;
    final providers = widget.items
        .map<ImageProvider<Object>>(
          (item) => ResizeImage.resizeIfNeeded(
            null,
            targetHeight,
            AssetImage(item.thumbnailPath),
          ),
        )
        .toList(growable: false);

    if (mounted) {
      setState(() {
        _imagesReady = false;
        _cardImageProviders = providers;
      });
    }

    await Future.wait(
      providers.map(
        (provider) => precacheImage(provider, context).catchError((_) {}),
      ),
    );

    if (!mounted || generation != _precacheGeneration) return;
    setState(() => _imagesReady = true);
  }

  void _handleScroll() {
    setState(() {
      _currentPage =
          _pageController.page ?? _pageController.initialPage.toDouble();
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_handleScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  void _showExpandedImage(BuildContext context, String imagePath) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.black.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.6);

    showDialog(
      context: context,
      barrierColor: Colors.transparent, // O BackdropFilter cuida do fundo
      builder: (context) {
        return Stack(
          children: [
            // Fundo escurecido com Blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(color: bgColor),
              ),
            ),
            // Imagem e Botão
            Center(
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: InteractiveViewer(
                        maxScale: 4.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.85,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 36),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final cardHeight = isMobile ? widget.height * 0.7 : widget.height;
        final cardWidth = isMobile ? 220.0 : 340.0;

        if (!_imagesReady) {
          return SizedBox(
            height: cardHeight,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        // Reduzimos o espaçamento no desktop para que as cartas fiquem mais concentradas
        // no centro e não esbarrem nas setas laterais.
        final baseSpacing = isMobile ? 120.0 : 160.0;

        // Cinco cards cobrem a área útil e reduzem drasticamente a quantidade
        // de camadas com perspectiva, sombra, clipping e opacidade.
        final int centerIndex = _currentPage.round();
        final int minIndex = centerIndex - 2;
        final int maxIndex = centerIndex + 2;

        List<int> visibleIndices = [
          for (var i = minIndex; i <= maxIndex; i++) i
        ];

        // Ordena para que o mais próximo do centro renderize por último (no topo)
        visibleIndices.sort((a, b) {
          final distA = (_currentPage - a).abs();
          final distB = (_currentPage - b).abs();
          return distB.compareTo(distA);
        });

        final carouselStack = SizedBox(
          height: cardHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Stack Visual
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: visibleIndices.map((index) {
                  final relativePosition = index - _currentPage;
                  final distance = relativePosition.abs();

                  double scale = 1.0 - (distance * 0.15);
                  scale = scale.clamp(0.70, 1.0);

                  double translateX = relativePosition * baseSpacing;

                  double opacity = 1.0 - (distance * 0.15);
                  opacity = opacity.clamp(0.0, 1.0);

                  double rotateY = -relativePosition * 0.10;
                  rotateY = rotateY.clamp(-0.25, 0.25);

                  // Resgata a imagem original mapeando o índice infinito
                  final realIndex = index % widget.items.length;

                  return Transform(
                    key: ValueKey<int>(index),
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..translateByDouble(translateX, 0.0, 0.0, 1.0)
                      ..rotateY(rotateY)
                      ..scaleByDouble(scale, scale, scale, 1.0),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: opacity,
                      child: RepaintBoundary(
                        child: Container(
                          width: cardWidth,
                          height: cardHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withAlpha((40 * opacity).toInt()),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image(
                              image: _cardImageProviders[realIndex],
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              gaplessPlayback: true,
                              isAntiAlias: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // 2. PageView Invisível para controle
              PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    behavior: HitTestBehavior
                        .opaque, // Garante que a área transparente receba o clique
                    onTap: () {
                      final int initialPageOffset =
                          (_loopOffset * widget.items.length) +
                              widget.initialPage;
                      final int currentPageInt =
                          _pageController.page?.round() ?? initialPageOffset;
                      if (currentPageInt == index) {
                        final realIndex = index % widget.items.length;
                        _showExpandedImage(
                            context, widget.items[realIndex].imagePath);
                      }
                    },
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ],
          ),
        );

        if (isMobile) {
          return carouselStack;
        }

        // 3. Layout com as setas do lado de fora do carrossel (100% fora das imagens)
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavButton(
                context: context,
                icon: Icons.chevron_left_rounded,
                onTap: _previousPage,
              ),
              const SizedBox(width: 16),
              // Expanded faz o carrossel tomar o espaço central sem invadir o espaço dos botões
              Expanded(
                child: carouselStack,
              ),
              const SizedBox(width: 16),
              _buildNavButton(
                context: context,
                icon: Icons.chevron_right_rounded,
                onTap: _nextPage,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tema dark: aspecto perolado/claro. Tema claro: preto meio transparente.
    final Color bgColor = isDark
        ? const Color(0xFFF0EBE1).withValues(alpha: 0.85) // Tom perolado
        : Colors.black.withValues(alpha: 0.5);

    final Color iconColor = isDark ? Colors.black87 : Colors.white;

    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(
            icon,
            size: 32,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
