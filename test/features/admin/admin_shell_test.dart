import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/admin/presentation/shell/admin_shell.dart';
import 'package:wedding_app/features/admin/presentation/products/admin_product_form_page.dart';

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
}
