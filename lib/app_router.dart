import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_navigation.dart';
import 'features/admin/presentation/admin_page.dart';
import 'features/admin/presentation/admin_page_route.dart';
import 'features/gifts/presentation/pages/gifts_page.dart';
import 'features/gifts/presentation/pages/payment_return_page.dart';
import 'features/wedding/presentation/pages/wedding_page.dart';

class AppRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(RouteInformation routeInformation) =>
      SynchronousFuture(_location(routeInformation.uri));

  @override
  RouteInformation restoreRouteInformation(String configuration) =>
      RouteInformation(uri: Uri.parse(configuration));

  static String _location(Uri uri) =>
      uri.path + (uri.hasQuery ? '?${uri.query}' : '');
}

class AppRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String>
    implements AppRouteHandler {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String _path = '/';

  @override
  String get currentConfiguration => _path;

  @override
  Future<void> setNewRoutePath(String configuration) {
    _setPath(configuration);
    return SynchronousFuture<void>(null);
  }

  @override
  void go(String path) => _setPath(path);

  void _setPath(String path) {
    if (_path == path) return;
    _path = path;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) => Navigator(
        key: navigatorKey,
        pages: [_pageFor(_path)],
        onDidRemovePage: (page) {
          if (page.key == ValueKey(_path)) go('/');
        },
      );

  Page<void> _pageFor(String path) {
    final uri = Uri.parse(path);
    final routePath = uri.path;
    if (routePath == '/admin' || routePath.startsWith('/admin/')) {
      return AdminRoutePage(
        key: ValueKey(path),
        name: path,
        child:
            AdminPage(path: routePath == '/admin' ? '/admin/dashboard' : path),
      );
    }
    if (routePath == '/') {
      return const MaterialPage<void>(
        key: ValueKey('/'),
        name: '/',
        child: WeddingPage(),
      );
    }
    if (routePath == '/presentes') {
      return const GiftsRoutePage(
        key: ValueKey('/presentes'),
        name: '/presentes',
      );
    }
    if (routePath == '/pagamento/retorno') {
      return MaterialPage<void>(
        key: ValueKey(path),
        name: path,
        child: PaymentReturnPage(orderId: uri.queryParameters['id'] ?? ''),
      );
    }
    return MaterialPage<void>(
      key: ValueKey(path),
      name: path,
      child: const Scaffold(body: Center(child: Text('Página não encontrada'))),
    );
  }
}

class GiftsRoutePage extends Page<void> {
  const GiftsRoutePage({required super.key, required super.name});

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
        settings: this,
        pageBuilder: (_, __, ___) => const GiftsPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      );
}

class AdminRoutePage extends Page<void> {
  final Widget child;

  const AdminRoutePage(
      {required super.key, required super.name, required this.child});

  @override
  Route<void> createRoute(BuildContext context) =>
      AdminPageRoute(settings: this, builder: (_) => child);
}
