import 'package:wedding_app/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/theme/app_colors.dart';
import '../widgets/wedding_header.dart';
import '../widgets/hero_section.dart';
import '../widgets/welcome_section.dart';
import '../widgets/countdown_section.dart';
import '../widgets/couple_section.dart';
import '../widgets/ceremony_section.dart';
import '../widgets/wedding_footer.dart';
import '../widgets/wedding_side_menu.dart';
import '../../../../app_router.dart';

class WeddingPage extends StatefulWidget {
  const WeddingPage({super.key});

  @override
  State<WeddingPage> createState() => _WeddingPageState();
}

class _WeddingPageState extends State<WeddingPage> {
  // Controlador compartilhado entre a barra lateral e CustomScrollView
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollProgressNotifier =
      ValueNotifier<double>(0.0);
  bool _isScrolled = false;

  // GlobalKeys para navegação por menu
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _casalKey = GlobalKey();
  final GlobalKey _recepcaoKey = GlobalKey();
  final GlobalKey _listaKey = GlobalKey();

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
        _scrollProgressNotifier.value =
            (currentScroll / maxScroll).clamp(0.0, 1.0);
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

    // A rolagem nativa permite usar a roda do mouse e arrastar a barra lateral.
    final Widget innerScrollView = CustomScrollView(
      controller: _scrollController,
      physics: isDesktopWeb
          ? const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            )
          : const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
      slivers: [
        SliverToBoxAdapter(
          key: _homeKey,
          child: HeroSection(scrollController: _scrollController),
        ),
        const SliverToBoxAdapter(
          child: WelcomeSection(),
        ),
        const SliverToBoxAdapter(
          child: CountdownSection(),
        ),
        SliverToBoxAdapter(
          key: _casalKey,
          child: CoupleSection(scrollController: _scrollController),
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
                    onPressed: () => AppNavigation.go(context, '/presentes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                    ),
                    child: const Text('VER LISTA DE PRESENTES'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: WeddingFooter(),
        ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: WeddingSideMenu(
        onHomeTap: () => _scrollTo(_homeKey),
        onCasalTap: () => _scrollTo(_casalKey),
        onRecepcaoTap: () => _scrollTo(_recepcaoKey),
        onListaTap: () {
          Navigator.of(context).pop(); // close drawer
          AppNavigation.go(context, '/presentes');
        },
        onRsvpTap: () {
          Navigator.of(context).pop();
          AppNavigation.go(context, AppRouterDelegate.rsvpNotice);
        },
      ),
      body: Stack(
        children: [
          Scrollbar(
            interactive: true,
            controller: _scrollController,
            thumbVisibility: !isMobile,
            trackVisibility: !isMobile,
            child: innerScrollView,
          ),
          WeddingHeader(
            isScrolled: _isScrolled,
            onHomeTap: () => _scrollTo(_homeKey),
            onCasalTap: () => _scrollTo(_casalKey),
            onRecepcaoTap: () => _scrollTo(_recepcaoKey),
            onListaTap: () => AppNavigation.go(context, '/presentes'),
            onRsvpTap: () =>
                AppNavigation.go(context, AppRouterDelegate.rsvpNotice),
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
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
