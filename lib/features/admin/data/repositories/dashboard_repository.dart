import '../../../../core/network/api_client.dart';
import '../models/dashboard_summary.dart';

class DashboardRepository {
  final ApiClient api;

  DashboardRepository(this.api);

  Future<DashboardSummary> getSummary() async {
    final response = await api.get('/api/admin/dashboard/summary');
    return DashboardSummary.fromJson(response);
  }

  Future<List<DashboardActivity>> getActivity({int limit = 10}) async {
    final response =
        await api.get('/api/admin/dashboard/activity?limit=$limit');
    final list = response as List;
    return list.map((e) => DashboardActivity.fromJson(e)).toList();
  }

  Future<List<dynamic>> getRecentAttendance() async {
    final response = await api.get('/api/admin/attendance?page=1&pageSize=5');
    return response['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getRecentPayments() async {
    final response = await api.get('/api/admin/payments?page=1&pageSize=3');
    return response['items'] as List<dynamic>;
  }
}
