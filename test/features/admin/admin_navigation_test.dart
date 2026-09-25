import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/app_router.dart';
import 'package:wedding_app/features/admin/presentation/admin_page_route.dart';
import 'package:wedding_app/features/admin/presentation/shell/admin_shell.dart';

void main() {
  const sections = [
    '/admin/dashboard',
    '/admin/produtos',
    '/admin/pagamentos',
    '/admin/presenca',
    '/admin/logs',
    '/admin/configuracoes',
    '/admin/seguranca',
  ];

  Widget app(String initialRoute, GlobalKey<NavigatorState> key) => MaterialApp(
        navigatorKey: key,
        initialRoute: initialRoute,
        onGenerateRoute: (settings) => AdminPageRoute(
          settings: settings,
          builder: (_) => AdminShell(
            currentPath: settings.name!,
            child: Center(child: Text('Conteúdo ${settings.name}')),
          ),
        ),
      );

  testWidgets(
      'navegação repetida mantém apenas um shell montado e permite voltar',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(app(sections.first, key));
    final history = [sections.first];
    for (final section in [...sections.skip(1), ...sections.skip(1)]) {
      key.currentState!.pushNamed(section);
      await tester.pumpAndSettle();
      history.add(section);
      expect(find.byType(AdminShell, skipOffstage: false), findsOneWidget);
      expect(find.text('Conteúdo $section'), findsOneWidget);
    }
    while (history.length > 1) {
      key.currentState!.pop();
      await tester.pumpAndSettle();
      history.removeLast();
      final section = history.last;
      expect(find.byType(AdminShell, skipOffstage: false), findsOneWidget);
      expect(find.text('Conteúdo $section'), findsOneWidget);
    }
  });

  testWidgets('rota administrativa direta monta um único shell',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(app('/admin/logs', key));
    expect(find.byType(AdminShell, skipOffstage: false), findsOneWidget);
    expect(find.text('Conteúdo /admin/logs'), findsOneWidget);
  });

  testWidgets(
      'router troca a seção ativa sem acumular páginas e restaura a URL',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));
    final parser = AppRouteInformationParser();
    final router = AppRouterDelegate();
    try {
      final direct = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/admin/produtos?page=2')),
      );
      expect(direct, '/admin/produtos?page=2');
      await router.setNewRoutePath(direct);
      expect(router.currentConfiguration, direct);
      expect(parser.restoreRouteInformation(direct).uri.toString(), direct);

      for (final path in [...sections, ...sections.reversed]) {
        router.go(path);
        expect(router.currentConfiguration, path);
        final navigator = router.build(context) as Navigator;
        expect(navigator.pages, hasLength(1));
        expect(navigator.pages.single, isA<AdminRoutePage>());
      }
      await router.setNewRoutePath('/admin/seguranca');
      expect(router.currentConfiguration, '/admin/seguranca');
    } finally {
      router.dispose();
    }
  });
}
