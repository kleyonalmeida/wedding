import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/core/network/api_client.dart';
import 'package:wedding_app/app_router.dart';
import 'package:wedding_app/features/gifts/data/models/payment_return_order.dart';
import 'package:wedding_app/features/gifts/data/repositories/payment_return_repository.dart';
import 'package:wedding_app/features/gifts/presentation/controllers/payment_return_controller.dart';
import 'package:wedding_app/features/gifts/presentation/pages/payment_return_page.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/gifts_theme.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/payment_return_status_card.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/payment_order_summary.dart';
import 'package:wedding_app/features/gifts/presentation/widgets/payment_return_help.dart';

const id = '11111111-1111-4111-8111-111111111111';
PaymentReturnOrder fixture({String status = 'Pending', int count = 1}) =>
    PaymentReturnOrder(
        id: id,
        status: status,
        totalCents: 9500 * count,
        currency: 'BRL',
        items: List.generate(
            count,
            (i) => PaymentReturnOrderItem(
                giftId: 'gift$i',
                name: 'Presente especial $i',
                unitPriceCents: 9500,
                quantity: 1)),
        senderName: 'Convidado',
        message: 'Muito carinho para vocês! ' * 12,
        createdAtUtc: DateTime.utc(2026, 9, 26),
        paymentMethod: 'CREDIT_CARD',
        receivedAtUtc: status == 'Received' ? DateTime.utc(2026, 9, 27) : null);

class FakeRepository extends PaymentReturnRepository {
  Future<PaymentReturnOrder?> Function(String, String) handler;
  int calls = 0;
  bool closed = false;
  FakeRepository(this.handler);
  @override
  Future<PaymentReturnOrder?> getOrderDetails(String id, String token) {
    calls++;
    return handler(id, token);
  }

  @override
  void dispose() {
    closed = true;
    super.dispose();
  }
}

void main() {
  test('router preserves fragment only on payment return and roundtrips',
      () async {
    final parser = AppRouteInformationParser();
    final route = await parser.parseRouteInformation(RouteInformation(
        uri: Uri.parse('/pagamento/retorno?id=$id#token=secret')));
    expect(parser.restoreRouteInformation(route).uri.fragment, 'token=secret');
    expect(
        await parser
            .parseRouteInformation(RouteInformation(uri: Uri.parse('/#other'))),
        '/');
  });
  test(
      'initial duplicates blocked, same-order token race discarded, client closed',
      () async {
    final old = Completer<PaymentReturnOrder?>();
    final next = Completer<PaymentReturnOrder?>();
    final repo =
        FakeRepository((_, token) => token == 'old' ? old.future : next.future);
    final controller = PaymentReturnController(repository: repo);
    controller.init(id, 'token=old');
    await controller.loadOrder();
    expect(repo.calls, 1);
    controller.init(id, 'token=new');
    next.complete(fixture(status: 'Received'));
    await Future<void>.delayed(Duration.zero);
    old.complete(fixture());
    await Future<void>.delayed(Duration.zero);
    expect(controller.order?.status, 'Received');
    controller.dispose();
    expect(repo.closed, isTrue);
    await controller.loadOrder();
    expect(repo.calls, 2);
  });
  test(
      'authorization failure removes stale details; malformed link avoids request',
      () async {
    final repo = FakeRepository((_, __) async => fixture());
    final c = PaymentReturnController(repository: repo);
    c.init('not-guid', 'token=x');
    expect(c.state, PaymentReturnState.invalidLink);
    expect(repo.calls, 0);
    c.init(id, 'token=x');
    await Future<void>.delayed(Duration.zero);
    repo.handler = (_, __) async => throw const ApiException(401);
    await c.loadOrder();
    expect(c.state, PaymentReturnState.inaccessible);
    expect(c.order, isNull);
    c.dispose();
  });
  for (final width in [320.0, 390.0, 768.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('pós-compra sem overflow $width escala $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final c = PaymentReturnController(
            repository: FakeRepository((_, __) async => fixture()));
        addTearDown(c.dispose);
        c.state = PaymentReturnState.success;
        c.order = fixture(status: 'Received', count: 30);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: Builder(
                builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: Theme(
                        data: giftsTheme(context),
                        child: Scaffold(
                            body: SingleChildScrollView(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: PaymentReturnStatusCard(
                                        controller: c)))))))));
        expect(tester.takeException(), isNull);
        expect(find.text('Cartão de crédito'), findsOneWidget);
        expect(find.textContaining('Contribuição recebida em'), findsOneWidget);
        expect(find.text('Presente especial 10'), findsNothing);
        await tester.ensureVisible(find.text('Próximos itens'));
        await tester.tap(find.text('Próximos itens'));
        await tester.pump();
        expect(find.text('Presente especial 10'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final status in [
    'Confirmed',
    'Received',
    'Pending',
    'Cancelled',
    'Overdue',
    'Refunded',
    'Disputed',
    'NEW_STATUS'
  ]) {
    testWidgets('estado $status tem conteúdo verdadeiro', (tester) async {
      final c = PaymentReturnController(
          repository: FakeRepository((_, __) async => fixture()));
      addTearDown(c.dispose);
      c.state = PaymentReturnState.success;
      c.order = fixture(status: status);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: PaymentReturnStatusCard(controller: c)))));
      expect(find.text('Aprovado e Notificado'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('refresh error appears with existing summary', (tester) async {
    final repo = FakeRepository((_, __) async => fixture());
    final c = PaymentReturnController(repository: repo);
    addTearDown(c.dispose);
    c.init(id, 'token=x');
    await tester.pump();
    repo.handler = (_, __) async => throw const ApiException(503);
    await c.loadOrder();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: PaymentReturnStatusCard(controller: c)))));
    expect(find.textContaining('Não foi possível atualizar.'), findsOneWidget);
    expect(find.byType(PaymentOrderSummary), findsOneWidget);
  });
  testWidgets('WhatsApp invalid configuration hides action', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home:
            Scaffold(body: PaymentReturnHelp(whatsappNumber: 'not-a-number'))));
    expect(find.text('Falar no WhatsApp'), findsNothing);
  });
  testWidgets('page updates when token changes without remount',
      (tester) async {
    final repo = FakeRepository((_, __) async => fixture());
    await tester.pumpWidget(MaterialApp(
        home: PaymentReturnPage(
            orderId: id, tokenFragment: 'token=first', repository: repo)));
    await tester.pumpAndSettle();
    expect(repo.calls, 1);
    await tester.pumpWidget(MaterialApp(
        home: PaymentReturnPage(
            orderId: id, tokenFragment: 'token=second', repository: repo)));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(tester.takeException(), isNull);
  });
}
