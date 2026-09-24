import '../models/rsvp_data.dart';
import '../../../../core/network/api_client.dart';

class RsvpRepository {
  final ApiClient _api = ApiClient();

  Future<void> submitRsvp(RsvpData data) async {
    if (!data.acceptTerms) {
      throw Exception('Você precisa aceitar os termos.');
    }
    await _api.post('/api/rsvp', {
      'nome': data.name,
      'email': data.email,
      'telefone': data.phone,
      'vaiComparecer': data.attending,
      'qtdAdultos': data.adults,
      'qtdCriancas': data.children,
      'observacoes': data.message.isEmpty ? null : data.message,
    });
  }
}
