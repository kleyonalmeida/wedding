import '../models/rsvp_data.dart';
import '../../../../core/network/api_client.dart';

class RsvpRepository {
  final ApiClient _api;

  RsvpRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<void> submitRsvp(RsvpData data) async {
    if (!data.acceptTerms) {
      throw Exception('Você precisa aceitar os termos.');
    }
    await _api.post('/api/rsvp', {
      'identificacaoNoConvite': data.identificacaoNoConvite,
      'email': data.email,
      'telefone': data.phone,
      'vaiComparecer': data.attending,
      'qtdCriancas': data.children,
      'aceitouTermos': data.acceptTerms,
    });
  }
}
