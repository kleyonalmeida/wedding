import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_smooth_scroll/web_smooth_scroll.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../wedding/presentation/widgets/wedding_header.dart';
import '../../../wedding/presentation/widgets/wedding_side_menu.dart';
import '../../../wedding/presentation/widgets/wedding_footer.dart';
import '../../../wedding/presentation/widgets/textured_background.dart';
import '../controllers/gift_catalog_controller.dart';
import '../widgets/gift_filter_panel.dart';
import '../widgets/gift_filter_sheet.dart';
import '../widgets/gift_sort_selector.dart';
import '../widgets/gift_product_grid.dart';

class GiftsPage extends StatefulWidget {
  const GiftsPage({super.key});

  @override
  State<GiftsPage> createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GiftCatalogController _catalogController = GiftCatalogController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final currentScroll = _scrollController.offset;
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
    _catalogController.dispose();
    super.dispose();
  }

  void _navigateHome(BuildContext context) {
    Navigator.of(context).pushNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isDesktopWeb = kIsWeb && !isMobile;

    final innerScrollView = CustomScrollView(
      controller: _scrollController,
      physics: isDesktopWeb
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 120, // Top padding to offset header
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 32.0, vertical: 32.0),
            child: ListenableBuilder(
              listenable: _catalogController,
              builder: (context, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMobile) ...[
                      SizedBox(
                        width: 256,
                        child: GiftFilterPanel(controller: _catalogController),
                      ),
                      const SizedBox(width: 32),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: GiftSortSelector(
                                  totalResults: _catalogController.totalResults,
                                  currentSort: _catalogController.currentFilter.sortOrder,
                                  onSortChanged: _catalogController.setSortOrder,
                                ),
                              ),
                              if (isMobile)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: OutlinedButton.icon(
                                    onPressed: () => GiftFilterSheet.show(context, _catalogController),
                                    icon: const Icon(Icons.filter_list, size: 20),
                                    label: const Text('Filtros'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                                      side: const BorderSide(color: AppColors.outlineVariant),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          GiftProductGrid(
                            products: _catalogController.products,
                            isLoading: _catalogController.isLoading,
                            hasMore: _catalogController.hasMore,
                            onLoadMore: () => _catalogController.loadProducts(),
                            error: _catalogController.error,
                            onRetry: () => _catalogController.loadProducts(refresh: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: WeddingFooter(),
        ),
      ],
    );

    final scrollArea = isDesktopWeb
        ? WebSmoothScroll(
            controller: _scrollController,
            scrollSpeed: 60,
            scrollAnimationLength: 500,
            curve: Curves.easeOutQuart,
            child: innerScrollView,
          )
        : innerScrollView;

    return Scaffold(
      key: _scaffoldKey,
      drawer: WeddingSideMenu(
        onHomeTap: () => _navigateHome(context),
        onCasalTap: () => _navigateHome(context),
        onRecepcaoTap: () => _navigateHome(context),
        onListaTap: () {}, // Already here
        onRsvpTap: () => _navigateHome(context),
      ),
      body: Stack(
        children: [
          TexturedBackground(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: !isMobile,
              trackVisibility: !isMobile,
              child: scrollArea,
            ),
          ),
          WeddingHeader(
            isScrolled: true, // Always solid on gifts page
            backgroundColor: const Color(0xFF957E6E),
            foregroundColor: Colors.white,
            onHomeTap: () => _navigateHome(context),
            onCasalTap: () => _navigateHome(context),
            onRecepcaoTap: () => _navigateHome(context),
            onListaTap: () {}, // Already here
            onRsvpTap: () => _navigateHome(context),
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
    );
  }
}
