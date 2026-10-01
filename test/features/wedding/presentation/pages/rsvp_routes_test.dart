import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/app_router.dart';

void main() {
  testWidgets('acesso direto ao formulário mostra aviso até o clique',
      (tester) async {
    final delegate = AppRouterDelegate();
    await tester.pumpWidget(MaterialApp.router(
      routeInformationProvider: PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(
          uri: Uri.parse(AppRouterDelegate.rsvpForm),
        ),
      ),
      routeInformationParser: AppRouteInformationParser(),
      routerDelegate: delegate,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(delegate.currentConfiguration, AppRouterDelegate.rsvpNotice);
    expect(find.text('ENTENDI, CONFIRMAR PRESENÇA'), findsOneWidget);
    expect(find.text('Identificação como está no convite'), findsNothing);

    await tester.ensureVisible(find.text('ENTENDI, CONFIRMAR PRESENÇA'));
    await tester.pump();
    await tester.tap(find.text('ENTENDI, CONFIRMAR PRESENÇA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(delegate.currentConfiguration, AppRouterDelegate.rsvpForm);
    expect(find.text('Identificação como está no convite'), findsOneWidget);
  });
}
