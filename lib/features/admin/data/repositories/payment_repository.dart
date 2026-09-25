import '../../../../core/network/api_client.dart';
import '../models/payment.dart';

class PaymentRepository {
  final ApiClient api;

  PaymentRepository(this.api);

  Future<PaginatedPayments> list({int page = 1, int pageSize = 20}) async {
    final response =
        await api.get('/api/admin/payments?page=$page&pageSize=$pageSize');
    final list = response['items'] as List;

    return PaginatedPayments(
      list.map((e) => PaymentListItem.fromJson(e)).toList(),
      response['total'] as int? ?? 0,
      response['page'] as int? ?? page,
      response['pageSize'] as int? ?? pageSize,
    );
  }

  Future<PaymentDetail> get(String id) async {
    final response = await api.get('/api/admin/payments/$id');
    return PaymentDetail.fromJson(response);
  }

  Future<List<PaymentEvent>> getEvents(String id) async {
    final response = await api.get('/api/admin/payments/$id/events');
    final list = response as List;
    return list.map((e) => PaymentEvent.fromJson(e)).toList();
  }

  Future<String> syncPayment(String id) async {
    final response = await api.post('/api/admin/payments/$id/sync', {});
    return response['status'] as String? ?? 'Unknown';
  }
}
