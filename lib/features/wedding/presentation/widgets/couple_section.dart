import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'cover_flow_carousel.dart';

class CoupleSection extends StatefulWidget {
  final ScrollController? scrollController;

  const CoupleSection({super.key, this.scrollController});

  @override
  State<CoupleSection> createState() => _CoupleSectionState();
}

class _CoupleSectionState extends State<CoupleSection> {
  static const _initialPage = 5;
  static const _items = <CarouselItem>[
    CarouselItem(
      imagePath: 'assets/images/_MG_1085.jpg',
      thumbnailPath: 'assets/images/carousel/_MG_1085.webp',
    ),
    CarouselItem(
      imagePath: 'assets/images/_MG_1064.jpg',
      thumbnailPath: 'assets/images/carousel/_MG_1064.webp',
    ),
    CarouselItem(
      imagePath: 'assets/images/_MG_1152.jpg',
      thumbnailPath: 'assets/images/carousel/_MG_1152.webp',
    ),
    CarouselItem(
      imagePath: 'assets/images/_MG_1229.jpg',
      thumbnailPath: 'assets/images/carousel/_MG_1229.webp',
    ),
    CarouselItem(
      imagePath: 'assets/images/_MG_1248.jpg',
      thumbnailPath: 'assets/images/carousel/_MG_1248.webp',
    ),
    CarouselItem(
      imagePath: 'assets/images/_MG_1288.jpg',
      thumbnailPath: 'assets/images/carousel/_MG_1288.webp',
    ),
    CarouselItem(
      imagePath: 'assets/images/_MG_1304.jpg',
      thumbnailPath: 'assets/images/carousel/_MG_1304.webp',
    ),
    CarouselItem(
      imagePath: 'assets/images/_MG_1333.jpg',
      thumbnailPath: 'assets/images/carousel/_MG_1333.webp',
    ),
    CarouselItem(
      imagePath: 'assets/images/_MG_1337.jpg',
      thumbnailPath: 'assets/images/carousel/_MG_1337.webp',
    ),
    CarouselItem(
      imagePath: 'assets/images/_MG_1341.jpg',
      thumbnailPath: 'assets/images/carousel/_MG_1341.webp',
    ),
  ];

  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(_initialPage);
  bool _isVisible = false;
  bool _visibilityCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_scheduleVisibilityCheck);
    _scheduleVisibilityCheck();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleVisibilityCheck();
  }

  @override
  void didUpdateWidget(covariant CoupleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_scheduleVisibilityCheck);
      widget.scrollController?.addListener(_scheduleVisibilityCheck);
      _scheduleVisibilityCheck();
    }
  }

  void _scheduleVisibilityCheck() {
    if (_visibilityCheckScheduled) return;
    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;
      if (!mounted) return;

      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final top = renderObject.localToGlobal(Offset.zero).dy;
      final viewportHeight = MediaQuery.sizeOf(context).height;
      final visible =
          top < viewportHeight && top + renderObject.size.height > 80;
      if (visible != _isVisible) setState(() => _isVisible = visible);
    });
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_scheduleVisibilityCheck);
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final sectionHeight = math.max(
          MediaQuery.sizeOf(context).height,
          isMobile ? 850.0 : 760.0,
        );
        final photoWidth = isMobile
            ? constraints.maxWidth
            : math.min(760.0, constraints.maxWidth * 0.72);

        return SizedBox(
          height: sectionHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF251D1B)),
              Center(
                child: SizedBox(
                  width: photoWidth,
                  height: sectionHeight,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _selectedIndex,
                    builder: (context, selectedIndex, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 650),
                        child: SizedBox.expand(
                          key: ValueKey<int>(selectedIndex),
                          child: Image.asset(
                            _items[selectedIndex].thumbnailPath,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.medium,
                            excludeFromSemantics: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xB8000000),
                      Color(0x85000000),
                      Color(0xB8000000),
                    ],
                    stops: [0.0, 0.48, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  isMobile ? 52 : 72,
                  24,
                  isMobile ? 48 : 64,
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'O Casal',
                        style: AppTextStyles.cursive.copyWith(
                          fontSize: isMobile ? 56 : 80,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 672),
                      child: Column(
                        children: [
                          Text(
                            '"Vamos nos casar!"',
                            style: AppTextStyles.serif.copyWith(
                              fontSize: 22,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Nossa história começou com um simples encontro que floresceu em uma jornada inesquecível de cumplicidade e amor. Cada passo que demos juntos nos trouxe a este momento sublime onde decidimos unir nossas vidas para sempre.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.sans.copyWith(
                              fontSize: 16,
                              height: 1.6,
                              color: AppColors.white.withValues(alpha: 0.92),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'NOSSA GALERIA',
                      style: AppTextStyles.sans.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deslize ou escolha uma foto. Toque na central para ampliar.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sans.copyWith(
                        fontSize: 12,
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CoverFlowCarousel(
                      items: _items,
                      height: 210,
                      initialPage: _initialPage,
                      autoPlay: _isVisible,
                      onPageChanged: (index) => _selectedIndex.value = index,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
