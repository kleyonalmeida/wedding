import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/admin/data/models/dashboard_summary.dart';
import 'package:wedding_app/features/admin/data/models/payment.dart';
import 'package:wedding_app/features/admin/presentation/widgets/admin_live_refresh.dart';

class RefreshProbe extends StatefulWidget {
  final Future<void> Function() onRefresh;
  const RefreshProbe({super.key, required this.onRefresh});

  @override
  State<RefreshProbe> createState() => _RefreshProbeState();
}

class _RefreshProbeState extends State<RefreshProbe>
    with AdminLiveRefresh<RefreshProbe> {
  @override
  Future<void> refreshData() => widget.onRefresh();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  test('arrecadação confirmada inclui confirmação sem confundir recebimento', () {
    final summary = DashboardSummary.fromJson({
      'payments': {
        'pending': 1,
        'totalConfirmedCents': 5200,
        'totalReceivedCents': 1000,
        'totalRaisedCents': 6200,
      },
    });
    expect(summary.payments.totalRaisedCents, 6200);
    expect(summary.payments.totalReceivedCents, 1000);
    expect(summary.payments.pending, 1);
  });

  test('pedido sem cobrança não inventa valor líquido nem habilita sync', () {
    final detail = PaymentDetail.fromJson({
      'id': 'order',
      'status': 'Pending',
      'amountCents': 5200,
      'netCents': null,
      'canSync': false,
      'billingType': null,
      'createdAtUtc': '2026-09-26T12:00:00Z',
    });
    expect(detail.netCents, isNull);
    expect(detail.canSync, isFalse);
    expect(detail.billingType, 'Ainda não informado');
  });

  testWidgets('refresh pausa na aba oculta, retoma e encerra no dispose',
      (tester) async {
    var calls = 0;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(MaterialApp(
      home: RefreshProbe(onRefresh: () async => calls++),
    ));
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 60));
    expect(calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 60));
    expect(calls, 2);
  });
}
