import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/wedding_header.dart';
import '../widgets/hero_section.dart';
import '../widgets/welcome_section.dart';
import '../widgets/countdown_section.dart';
import '../widgets/couple_section.dart';
import '../widgets/godparents_section.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // GlobalKeys for navigation
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _casalKey = GlobalKey();
  final GlobalKey _padrinhosKey = GlobalKey();
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
      if (_scrollController.offset > 100 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 100 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    return Scaffold(
      key: _scaffoldKey,
      drawer: WeddingSideMenu(
        onHomeTap: () => _scrollTo(_homeKey),
        onCasalTap: () => _scrollTo(_casalKey),
        onPadrinhosTap: () => _scrollTo(_padrinhosKey),
        onRecepcaoTap: () => _scrollTo(_recepcaoKey),
        onListaTap: () => _scrollTo(_listaKey),
        onRsvpTap: () => _scrollTo(_rsvpKey),
      ),
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
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
                  key: _padrinhosKey,
                  child: GodparentsSection(),
                ),
                SliverToBoxAdapter(
                  key: _recepcaoKey,
                  child: const CeremonySection(),
                ),
                SliverToBoxAdapter(
                  key: _listaKey,
                  child: Container(
                    height: 300,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: const Center(
                      child: Text(
                        "Lista de Presentes (Em breve)",
                        style: TextStyle(color: AppColors.primary, fontSize: 24),
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
            ),
          ),
          WeddingHeader(
            isScrolled: _isScrolled,
            onHomeTap: () => _scrollTo(_homeKey),
            onCasalTap: () => _scrollTo(_casalKey),
            onPadrinhosTap: () => _scrollTo(_padrinhosKey),
            onRecepcaoTap: () => _scrollTo(_recepcaoKey),
            onListaTap: () => _scrollTo(_listaKey),
            onRsvpTap: () => _scrollTo(_rsvpKey),
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
    );
  }
}

