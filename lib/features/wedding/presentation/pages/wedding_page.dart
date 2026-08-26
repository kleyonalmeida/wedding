import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/widgets/smooth_web_scroll.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/wedding_header.dart';
import '../widgets/hero_section.dart';
import '../widgets/welcome_section.dart';
import '../widgets/countdown_section.dart';
import '../widgets/couple_section.dart';
import '../widgets/ceremony_section.dart';
import '../widgets/rsvp_section.dart';
import '../widgets/wedding_footer.dart';
import '../widgets/wedding_side_menu.dart';

class WeddingPage extends StatefulWidget {
  const WeddingPage({super.key});

  @override
  State<WeddingPage> createState() => _WeddingPageState();
}

class _WeddingPageState extends State<WeddingPage> {
  // Controlador único: compartilhado entre WebSmoothScroll e CustomScrollView
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollProgressNotifier = ValueNotifier<double>(0.0);
  bool _isScrolled = false;

  // GlobalKeys para navegação por menu
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _casalKey = GlobalKey();
  final GlobalKey _recepcaoKey = GlobalKey();
  final GlobalKey _listaKey = GlobalKey();
  final GlobalKey _rsvpKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (maxScroll > 0) {
        _scrollProgressNotifier.value = (currentScroll / maxScroll).clamp(0.0, 1.0);
      }

      if (currentScroll > 100 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (currentScroll <= 100 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollProgressNotifier.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final renderObject = ctx.findRenderObject();
    if (renderObject == null) return;

    final viewport = RenderAbstractViewport.of(renderObject);
    final revealed = viewport.getOffsetToReveal(renderObject, 0.0);

    double targetOffset = revealed.offset - 80.0;
    if (_scrollController.hasClients) {
      targetOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isDesktopWeb = kIsWeb && !isMobile;

    // Widget de rolagem interno — usa NeverScrollableScrollPhysics no desktop web
    // para que o WebSmoothScroll assuma o controle exclusivo do scroll.
    final Widget innerScrollView = CustomScrollView(
      controller: _scrollController,
      physics: isDesktopWeb
          ? const NeverScrollableScrollPhysics() // Obrigatório: desativa o scroll nativo "duro"
          : const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
      slivers: [
        SliverToBoxAdapter(
          key: _homeKey,
          child: const HeroSection(),
        ),
        const SliverToBoxAdapter(
          child: WelcomeSection(),
        ),
        const SliverToBoxAdapter(
          child: CountdownSection(),
        ),
        SliverToBoxAdapter(
          key: _casalKey,
          child: const CoupleSection(),
        ),
        SliverToBoxAdapter(
          key: _recepcaoKey,
          child: const CeremonySection(),
        ),
        SliverToBoxAdapter(
          key: _listaKey,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Lista de Presentes",
                    style: TextStyle(
                      fontFamily: 'Bodoni Moda',
                      color: AppColors.primary,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Fizemos uma seleção com muito carinho.",
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/presentes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: const Text('VER LISTA DE PRESENTES'),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          key: _rsvpKey,
          child: const RsvpSection(),
        ),
        const SliverToBoxAdapter(
          child: WeddingFooter(),
        ),
      ],
    );

    // Widget pai de scroll: no desktop web usa SmoothWebScroll,
    // no mobile usa o CustomScrollView diretamente (física nativa já é suave).
    final Widget scrollArea = isDesktopWeb
        ? SmoothWebScroll(
            controller: _scrollController, 
            scrollAmount: 80,              // Distância reduzida por tick do mouse
            animationDuration: const Duration(milliseconds: 500), // Duração da inércia
            child: innerScrollView,
          )
        : innerScrollView;

    return Scaffold(
      key: _scaffoldKey,
      drawer: WeddingSideMenu(
        onHomeTap: () => _scrollTo(_homeKey),
        onCasalTap: () => _scrollTo(_casalKey),
        onRecepcaoTap: () => _scrollTo(_recepcaoKey),
        onListaTap: () {
          Navigator.of(context).pop(); // close drawer
          Navigator.of(context).pushNamed('/presentes');
        },
        onRsvpTap: () => _scrollTo(_rsvpKey),
      ),
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: !isMobile,
            trackVisibility: !isMobile,
            child: scrollArea,
          ),
          WeddingHeader(
            isScrolled: _isScrolled,
            onHomeTap: () => _scrollTo(_homeKey),
            onCasalTap: () => _scrollTo(_casalKey),
            onRecepcaoTap: () => _scrollTo(_recepcaoKey),
            onListaTap: () => Navigator.of(context).pushNamed('/presentes'),
            onRsvpTap: () => _scrollTo(_rsvpKey),
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          if (isMobile)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollProgressNotifier,
                builder: (context, progress, child) {
                  return LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4.0,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
