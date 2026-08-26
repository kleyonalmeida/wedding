import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:web_smooth_scroll/web_smooth_scroll.dart';
import '../widgets/wedding_header.dart';
import '../widgets/hero_section.dart';
import '../widgets/welcome_section.dart';
import '../widgets/countdown_section.dart';
import '../widgets/couple_section.dart';
import '../widgets/godparents_section.dart';
import '../widgets/ceremony_section.dart';
import '../widgets/rsvp_section.dart';
import '../widgets/wedding_footer.dart';

class WeddingPage extends StatefulWidget {
  const WeddingPage({super.key});

  @override
  State<WeddingPage> createState() => _WeddingPageState();
}

class _WeddingPageState extends State<WeddingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // GlobalKeys for navigation
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
    if (_scrollController.offset > 100 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 100 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebSmoothScroll(
            controller: _scrollController,
            scrollSpeed: 4.0,
            scrollAnimationLength: 800,
            curve: Curves.easeOutExpo,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
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
                  color: AppColors.surface,
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
          ),
        ],
      ),
    );
  }
}
