import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/admin/presentation/shell/admin_shell.dart';
import 'package:wedding_app/features/admin/presentation/products/admin_product_form_page.dart';
import 'package:wedding_app/features/admin/presentation/widgets/admin_metric_card.dart';
import 'package:wedding_app/features/admin/presentation/widgets/admin_metric_grid.dart';
import 'package:wedding_app/features/admin/presentation/theme/admin_theme.dart';

void main() {
  testWidgets('menu mobile abre o drawer com as rotas administrativas',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: AdminShell(
        currentPath: '/admin/dashboard',
        child: Center(child: Text('Conteúdo')),
      ),
    ));
    expect(find.text('Conteúdo'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Produtos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('formulário de produto cabe em tela estreita', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AdminProductFormPage()),
    ));
    expect(find.text('Nome do Produto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('indicador compacto acomoda valor e progresso', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AdminTheme.theme,
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 220,
            height: 150,
            child: AdminMetricCard(
              label: 'PRESENÇA CONFIRMADA',
              value: '1.234',
              suffixText: 'pessoas',
              icon: Icons.people,
              progress: 0.75,
              progressLabel: 'Respostas recebidas',
              progressValue: '75%',
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('indicadores sem progresso usam apenas a altura necessária',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AdminTheme.theme,
      home: const Scaffold(
        body: SizedBox(
          width: 1000,
          child: AdminMetricGrid(children: [
            AdminMetricCard(
              label: 'PRESENÇA',
              value: '24',
              icon: Icons.people,
              progress: 0.75,
              progressLabel: 'Confirmados',
              progressValue: '75%',
            ),
            AdminMetricCard(
                label: 'PRODUTOS', value: '10', icon: Icons.inventory_2),
          ]),
        ),
      ),
    ));
    final cards = find.byType(AdminMetricCard);
    expect(tester.getSize(cards.at(1)).height,
        lessThan(tester.getSize(cards.first).height));
    expect(tester.takeException(), isNull);
  });
}
