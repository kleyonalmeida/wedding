import '../models/rsvp_data.dart';

class RsvpRepository {
  Future<void> submitRsvp(RsvpData data) async {
    // Fake repository implementation
    await Future.delayed(const Duration(seconds: 2));
    
    // Simular algum caso de erro se necessário
    if (!data.acceptTerms) {
      throw Exception('Você precisa aceitar os termos.');
    }
    
    // Sucesso
    return;
  }
}
