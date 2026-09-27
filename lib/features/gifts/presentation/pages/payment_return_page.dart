import 'package:flutter/material.dart';
import '../controllers/payment_return_controller.dart';
import '../../data/repositories/payment_return_repository.dart';
import '../widgets/payment_return_heading.dart';
import '../widgets/payment_return_status_card.dart';
import '../widgets/gifts_theme.dart';
import '../../../wedding/presentation/widgets/wedding_header.dart';
import '../../../wedding/presentation/widgets/wedding_footer.dart';
import '../../../wedding/presentation/widgets/wedding_side_menu.dart';
import 'package:wedding_app/app_navigation.dart';

class PaymentReturnPage extends StatefulWidget {
  final String orderId;
  final String? tokenFragment;
  final PaymentReturnRepository? repository;
  final String whatsappNumber;
  const PaymentReturnPage(
      {super.key,
      required this.orderId,
      this.tokenFragment,
      this.repository,
      this.whatsappNumber =
          const String.fromEnvironment('GROOM_WHATSAPP_NUMBER')});
  @override
  State<PaymentReturnPage> createState() => _PaymentReturnPageState();
}

class _PaymentReturnPageState extends State<PaymentReturnPage>
    with SingleTickerProviderStateMixin {
  late final PaymentReturnController _controller;
  late final AnimationController _entry;
  late final Animation<double> _fade;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scroll = ScrollController();
  bool _started = false;
  @override
  void initState() {
    super.initState();
    _controller = PaymentReturnController(repository: widget.repository);
    _controller.init(widget.orderId, widget.tokenFragment ?? Uri.base.fragment);
    _entry = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entry.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _entry.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PaymentReturnPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.tokenFragment != widget.tokenFragment) {
      _controller.init(
          widget.orderId, widget.tokenFragment ?? Uri.base.fragment);
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _go(String path) => AppNavigation.replace(context, path);
  @override
  Widget build(BuildContext context) {
    final localTheme = giftsTheme(context);
    final desktop = MediaQuery.sizeOf(context).width >= 768;
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? localTheme.colorScheme.surfaceContainerLow
            : const Color(0xfffbf9f8),
        drawer: WeddingSideMenu(
            onHomeTap: () => _go('/'),
            onCasalTap: () => _go('/'),
            onRecepcaoTap: () => _go('/'),
            onListaTap: () => _go('/presentes'),
            onRsvpTap: () => _go('/')),
        body: Stack(children: [
          Scrollbar(
              controller: _scroll,
              child: CustomScrollView(controller: _scroll, slivers: [
                SliverToBoxAdapter(
                    child: SizedBox(height: 120 + (desktop ? 80 : 48))),
                SliverToBoxAdapter(
                    child: FadeTransition(
                        opacity: _fade,
                        child: Theme(
                            data: localTheme,
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(children: [
                                  const PaymentReturnHeading(),
                                  ListenableBuilder(
                                      listenable: _controller,
                                      builder: (context, _) =>
                                          PaymentReturnStatusCard(
                                              controller: _controller,
                                              whatsappNumber:
                                                  widget.whatsappNumber)),
                                  const SizedBox(height: 80),
                                ]))))),
                const SliverToBoxAdapter(child: WeddingFooter()),
              ])),
          WeddingHeader(
              isScrolled: true,
              backgroundColor: const Color(0xFF957E6E),
              foregroundColor: Colors.white,
              onHomeTap: () => _go('/'),
              onCasalTap: () => _go('/'),
              onRecepcaoTap: () => _go('/'),
              onListaTap: () => _go('/presentes'),
              onRsvpTap: () => _go('/'),
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
        ]));
  }
}
