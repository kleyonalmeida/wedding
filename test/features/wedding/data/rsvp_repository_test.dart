import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wedding_app/core/network/api_client.dart';
import 'package:wedding_app/features/wedding/data/models/rsvp_data.dart';
import 'package:wedding_app/features/wedding/data/repositories/rsvp_repository.dart';

RsvpData _rsvp() => RsvpData(
      identificacaoNoConvite: 'jorge e amanda',
      attending: true,
      children: 2,
      email: 'jorge@example.com',
      phone: '11987654321',
      acceptTerms: true,
    );

void main() {
  test('envia aceite dos termos e não informa quantidade de adultos', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/rsvp');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['identificacaoNoConvite'], 'jorge e amanda');
      expect(body['aceitouTermos'], true);
      expect(body['qtdCriancas'], 2);
      expect(body.containsKey('qtdAdultos'), false);
      return http.Response('{"id":"ok"}', 201);
    });

    await RsvpRepository(api: ApiClient(client: client)).submitRsvp(_rsvp());
  });

  test('preserva código de negócio da API para o modal correto', () async {
    final client = MockClient((request) async => http.Response(
          '{"code":"INVITATION_NOT_FOUND","message":"Não encontrada"}',
          422,
        ));

    await expectLater(
      RsvpRepository(api: ApiClient(client: client)).submitRsvp(_rsvp()),
      throwsA(isA<ApiException>()
          .having((error) => error.code, 'code', 'INVITATION_NOT_FOUND')),
    );
  });
}
