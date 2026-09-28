import 'package:wedding_app/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/constants/wedding_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smooth_web_scroll.dart';
import '../../../../core/widgets/web_scroll_mode.dart';
import '../../../wedding/presentation/widgets/wedding_header.dart';
import '../../../wedding/presentation/widgets/wedding_side_menu.dart';
import '../../../wedding/presentation/widgets/wedding_footer.dart';
import '../../../wedding/presentation/widgets/textured_background.dart';
import '../controllers/gift_catalog_controller.dart';
import '../controllers/cart_controller.dart';
import '../../data/repositories/gift_repository.dart';
import '../widgets/gift_product_grid.dart';
import '../widgets/gift_checkout_flow.dart';
import '../widgets/gifts_theme.dart';
import '../widgets/gifts_hero_section.dart';
import '../widgets/gifts_category_chips.dart';
import '../widgets/gifts_closing_section.dart';
import '../widgets/gifts_pix_section.dart';
import '../widgets/gift_dedication_modal.dart';

class GiftsPage extends StatefulWidget {
  final GiftRepository? repository;
  const GiftsPage({super.key, this.repository});

  @override
  State<GiftsPage> createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final GiftCatalogController _catalogController;
  final CartController _cartController = CartController();
  String _selectedCategory = 'todas';

  @override
  void initState() {
    super.initState();
    _catalogController = GiftCatalogController(repository: widget.repository);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _catalogController.dispose();
    _cartController.dispose();
    super.dispose();
  }

  void _navigateHome(BuildContext context) {
    AppNavigation.go(context, '/');
  }

  void _openPersonalizedGift() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Theme(
        data: giftsTheme(context),
        child: GiftDedicationModal(
          itemTitle: 'Presente Personalizado',
          itemValue: 'Valor a definir por você',
          isCustomAmount: true,
          onClose: () => Navigator.of(dialogContext).pop(),
          onConfirm: (name, message, amount) {
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Obrigado pelo carinho. Conclua a transferência na chave PIX desta página.',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isDesktopWeb = kIsWeb && !isMobile;
    final useSmoothWebScroll =
        isDesktopWeb && resolveWebScrollMode() == WebScrollMode.smooth;

    final catalogTheme = giftsTheme(context);
    final innerScrollView = CustomScrollView(
      controller: _scrollController,
      physics: useSmoothWebScroll
          ? const NeverScrollableScrollPhysics()
          : isDesktopWeb
              ? const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                )
              : const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 24),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 896),
                child:
                    Theme(data: catalogTheme, child: const GiftsHeroSection()),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20.0 : 32.0, vertical: 40.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Theme(
                    data: catalogTheme,
                    child: GiftsCategoryChips(
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (category) {
                        setState(() => _selectedCategory = category);
                        _catalogController.selectCategory(category);
                      },
                      onSearchChanged: _catalogController.updateSearch,
                    )),
              ),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: _catalogController,
          builder: (context, _) => Theme(
              data: catalogTheme,
              child: GiftProductGrid(
                products: _catalogController.products,
                isLoading: _catalogController.isLoading,
                hasMore: _catalogController.hasMore,
                onLoadMore: () => _catalogController.loadProducts(),
                error: _catalogController.error,
                onRetry: () => _catalogController.loadProducts(refresh: true),
                cartController: _cartController,
              )),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 20 : 32,
              64,
              isMobile ? 20 : 32,
              0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Theme(
                  data: catalogTheme,
                  child: GiftsPixSection(
                    pixKey: WeddingConstants.pixKey,
                    onAddMessage: _openPersonalizedGift,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
            child: Theme(
                data: catalogTheme,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: GiftsClosingSection(),
                ))),
        const SliverToBoxAdapter(
          child: WeddingFooter(),
        ),
      ],
    );

    final scrollArea = useSmoothWebScroll
        ? SmoothWebScroll(
            controller: _scrollController,
            scrollAmount: 80,
            animationDuration: const Duration(milliseconds: 500),
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
      floatingActionButton: ListenableBuilder(
        listenable: _cartController,
        builder: (context, _) {
          if (_cartController.items.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => showGiftCart(context, _cartController,
                () => _catalogController.loadProducts(refresh: true)),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              '${_cartController.itemCount} itens',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
      body: Column(
        children: [
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
          Expanded(
            child: TexturedBackground(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: !isMobile,
                trackVisibility: !isMobile,
                child: scrollArea,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
