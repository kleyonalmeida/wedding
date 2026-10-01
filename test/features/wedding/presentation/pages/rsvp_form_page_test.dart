import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wedding_app/core/network/api_client.dart';
import 'package:wedding_app/features/wedding/data/repositories/rsvp_repository.dart';
import 'package:wedding_app/features/wedding/presentation/pages/rsvp_form_page.dart';

void main() {
  testWidgets('nome não cadastrado abre modal com o texto digitado',
      (tester) async {
    final client = MockClient((request) async => http.Response(
          '{"code":"INVITATION_NOT_FOUND","message":"Não encontrada"}',
          422,
        ));
    await tester.pumpWidget(MaterialApp(
      home: RsvpFormPage(
        repository: RsvpRepository(api: ApiClient(client: client)),
      ),
    ));
    await tester.pump();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Identificação como está no convite'),
        'jorge e amanda');
    await tester.ensureVisible(find.text('Sim, confirmarei'));
    await tester.tap(find.text('Sim, confirmarei'));
    await tester.pump();
    await tester.ensureVisible(find.text('Não').last);
    await tester.tap(find.text('Não').last);
    await tester.enterText(find.widgetWithText(TextFormField, 'E-MAIL'),
        'jorge@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'TELEFONE / WHATSAPP'),
        '11987654321');
    await tester.ensureVisible(find.text('Li e aceito os termos de uso.'));
    await tester.tap(find.text('Li e aceito os termos de uso.'));
    await tester.ensureVisible(find.text('CONFIRMAR PRESENÇA'));
    await tester.tap(find.text('CONFIRMAR PRESENÇA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Identificação não encontrada'), findsOneWidget);
    expect(find.textContaining('jorge e amanda'), findsWidgets);
  });

  testWidgets('formulário estreito pergunta apenas a quantidade de crianças',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: RsvpFormPage()));
    await tester.pump();

    expect(find.text('Identificação como está no convite'), findsOneWidget);
    expect(find.text('Terá acompanhante?'), findsNothing);
    await tester.ensureVisible(find.text('Sim, confirmarei'));
    await tester.tap(find.text('Sim, confirmarei'));
    await tester.pump();
    expect(find.text('LEVARÃO CRIANÇAS?'), findsOneWidget);
    await tester.ensureVisible(find.text('Sim').last);
    await tester.tap(find.text('Sim').last);
    await tester.pump();
    expect(find.text('QUANTIDADE DE CRIANÇAS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
