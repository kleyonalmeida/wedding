import '../../../../core/network/api_client.dart';
import '../models/audit_log.dart';

class AuditRepository {
  final ApiClient api;

  AuditRepository(this.api);

  Future<PaginatedAuditLogs> list({int page = 1, int pageSize = 20}) async {
    final response =
        await api.get('/api/admin/audit-logs?page=$page&pageSize=$pageSize');

    // Check if the response contains 'data' or 'items' list
    final listData = response['data'] ?? response['items'];
    if (listData == null || listData is! List) {
      throw Exception('Formato de resposta inválido de /api/admin/audit-logs');
    }

    return PaginatedAuditLogs(
      listData.map((e) => AuditLog.fromJson(e)).toList(),
      response['totalPages'] as int? ?? 1,
      response['page'] as int? ?? page,
      response['pageSize'] as int? ?? pageSize,
      response['total'] as int? ?? 0,
    );
  }

  Future<AuditLog> get(String id) async {
    final response = await api.get('/api/admin/audit-logs/$id');
    return AuditLog.fromJson(response);
  }
}
