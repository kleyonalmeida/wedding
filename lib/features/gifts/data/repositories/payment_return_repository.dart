import '../../../../core/network/api_client.dart';
import '../models/payment_return_order.dart';

class PaymentReturnRepository {
  final ApiClient _apiClient;

  PaymentReturnRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<PaymentReturnOrder?> getOrderDetails(String id, String token) async {
    final response = await _apiClient.get(
        '/api/gift-orders/${Uri.encodeComponent(id)}?token=${Uri.encodeQueryComponent(token)}');
    if (response == null) {
      return null;
    }
    return PaymentReturnOrder.fromJson(response as Map<String, dynamic>);
  }

  void dispose() => _apiClient.dispose();
}
