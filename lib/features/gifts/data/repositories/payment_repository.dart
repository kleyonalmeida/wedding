import 'dart:math';
import '../../../../core/network/api_client.dart';

class PaymentRepository {
  final ApiClient _apiClient = ApiClient();
  final String _idempotencyKey = _newKey();

  static String _newKey() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<String?> createGiftOrder({
    required String senderName,
    String? message,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _apiClient.post('/api/gift-orders', {
      'senderName': senderName,
      'message': message,
      'items': items,
      'idempotencyKey': _idempotencyKey,
    });
    return response['checkoutUrl'];
  }
}
