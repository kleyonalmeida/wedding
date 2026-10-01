import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wedding_app/core/network/api_client.dart';
import 'package:wedding_app/features/admin/data/repositories/invitation_line_repository.dart';
import 'package:wedding_app/features/admin/data/models/rsvp.dart';
import 'package:wedding_app/features/admin/presentation/attendance/admin_invitation_lines_page.dart';

void main() {
  test('resumo do Admin lê as contagens devolvidas pela API', () {
    final summary = AttendanceSummary.fromJson({
      'linhasPendentes': 3,
      'linhasConfirmadas': 2,
      'linhasRecusadas': 1,
      'totalAdultos': 4,
      'totalCriancas': 2,
      'totalPessoas': 6,
    });
    expect(summary.totalRespostas, 3);
    expect(summary.confirmados, 2);
    expect(summary.naoVao, 1);
    expect(summary.linhasPendentes, 3);
    expect(summary.totalPessoas, 6);
  });

  testWidgets(
      'Admin cadastra uma linha com dois adultos e vê o estado pendente',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var created = false;
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        expect(request.body,
            contains('"identificacaoNoConvite":"Jorge e Amanda"'));
        expect(request.body, contains('"quantidadeAdultos":2'));
        created = true;
        return http.Response('{}', 201);
      }
      return http.Response(
        created
            ? '{"data":[{"id":"1","identificacaoNoConvite":"Jorge e Amanda","quantidadeAdultos":2,"ativo":true,"respondida":false,"rsvp":null}],"total":1,"totalPages":1}'
            : '{"data":[],"total":0,"totalPages":0}',
        200,
      );
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AdminInvitationLinesPage(
          repository: InvitationLineRepository(ApiClient(client: client)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo convite'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Identificação como no convite'),
        'Jorge e Amanda');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade de adultos'), '2');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(created, isTrue);
    expect(find.text('Jorge e Amanda'), findsOneWidget);
    expect(find.textContaining('2 adulto(s) • Pendente'), findsOneWidget);
  });
}
