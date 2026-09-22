import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class CarouselItem {
  final String imagePath;
  final String? title;

  const CarouselItem({
    required this.imagePath,
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

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.toDouble();
    _pageController = PageController(
      initialPage: widget.initialPage,
      viewportFraction: 1.0, // O PageView ocupa toda a largura para o scroll nativo
    );
    _pageController.addListener(_handleScroll);
  }

  void _handleScroll() {
    setState(() {
      _currentPage = _pageController.page ?? _pageController.initialPage.toDouble();
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
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Tratado pelo BackdropFilter
      builder: (context) {
        return Stack(
          children: [
            // Fundo desfocado
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
            // Imagem interativa
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
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.85,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 36),
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
        final baseSpacing = isMobile ? 120.0 : 200.0;
        
        // O último card visível claramente fica em distance=2.
        // O centro dele é deslocado em 2 * baseSpacing = 400px.
        // A escala é 0.7, então a largura é 340 * 0.7 = 238. A borda fica a 400 + 119 = 519px do centro.
        // Para colocar a seta fora desse card, afastamos cerca de 580px do centro.
        final double idealArrowOffset = (constraints.maxWidth / 2) - 580.0;
        final double arrowOffset = idealArrowOffset > 16.0 ? idealArrowOffset : 16.0;

        // Ordenar os índices pela distância até a página atual (decrescente).
        // Isso garante que o card mais próximo (centro) seja renderizado por último (topo do Stack).
        List<int> orderedIndices = List.generate(widget.items.length, (i) => i);
        orderedIndices.sort((a, b) {
          final distA = (_currentPage - a).abs();
          final distB = (_currentPage - b).abs();
          return distB.compareTo(distA);
        });

        return SizedBox(
          height: cardHeight,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Stack Visual: Desenha os cards aplicando as transformações
              Stack(
                alignment: Alignment.center,
                children: orderedIndices.map((index) {
                  final relativePosition = index - _currentPage;
                  final distance = relativePosition.abs();

                  // Limita a renderização aos cards próximos para performance
                  if (distance > 3.5) return const SizedBox.shrink();

                  // Escala: 1.0 no centro, diminui progressivamente
                  double scale = 1.0 - (distance * 0.15);
                  scale = scale.clamp(0.70, 1.0);

                  // Translação: move os cards lateralmente baseado no espaçamento base
                  double translateX = relativePosition * baseSpacing;

                  // Opacidade: diminui sutilmente para cards distantes
                  double opacity = 1.0 - (distance * 0.15);
                  opacity = opacity.clamp(0.0, 1.0);

                  // Rotação Y muito sutil
                  double rotateY = -relativePosition * 0.10;
                  rotateY = rotateY.clamp(-0.25, 0.25);

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspectiva para a rotação 3D
                      ..translate(translateX, 0.0, 0.0)
                      ..rotateY(rotateY)
                      ..scale(scale),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((40 * opacity).toInt()),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            widget.items[index].imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // 2. PageView Invisível: Captura swipes e scroll wheel perfeitamente
              PageView.builder(
                controller: _pageController,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Permite expandir a imagem apenas se ela for a imagem central atual
                      final int currentPageInt = _pageController.page?.round() ?? widget.initialPage;
                      if (currentPageInt == index) {
                        _showExpandedImage(context, widget.items[index].imagePath);
                      }
                    },
                    child: const SizedBox.expand(),
                  );
                },
              ),

              // 3. Controles (Setas) de Navegação
              if (!isMobile)
                Positioned(
                  left: arrowOffset,
                  child: _buildNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: _previousPage,
                  ),
                ),
              if (!isMobile)
                Positioned(
                  right: arrowOffset,
                  child: _buildNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _nextPage,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.8),
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
            color: const Color(0xFF957E6E), // Cor primária / marrom suave
          ),
        ),
      ),
    );
  }
}
