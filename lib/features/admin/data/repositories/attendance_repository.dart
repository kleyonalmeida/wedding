import '../../../../core/network/api_client.dart';
import '../models/rsvp.dart';

class AttendanceRepository {
  final ApiClient api;

  AttendanceRepository(this.api);

  Future<PaginatedRsvps> list(
      {int page = 1,
      int pageSize = 20,
      String? search,
      bool? vaiComparecer}) async {
    final query = <String>[];
    query.add('page=$page');
    query.add('pageSize=$pageSize');
    if (search != null && search.isNotEmpty) {
      query.add('search=${Uri.encodeQueryComponent(search)}');
    }
    if (vaiComparecer != null) query.add('vaiComparecer=$vaiComparecer');

    final response = await api.get('/api/admin/attendance?${query.join('&')}');

    final list = response['data'] as List;
    return PaginatedRsvps(
      list.map((e) => Rsvp.fromJson(e)).toList(),
      response['totalPages'] as int? ?? 1,
      response['page'] as int? ?? page,
      response['total'] as int? ?? 0,
    );
  }

  Future<AttendanceSummary> getSummary() async {
    final response = await api.get('/api/admin/attendance/summary');
    return AttendanceSummary.fromJson(response);
  }

  Future<Rsvp> get(String id) async {
    final response = await api.get('/api/admin/attendance/$id');
    return Rsvp.fromJson(response);
  }

  Future<Rsvp> patch(
    String id, {
    bool? vaiComparecer,
    int? qtdAdultos,
    int? qtdCriancas,
    String? observacoes,
    required String motivo,
  }) async {
    final data = <String, dynamic>{
      'motivo': motivo,
    };
    if (vaiComparecer != null) data['vaiComparecer'] = vaiComparecer;
    if (qtdAdultos != null) data['qtdAdultos'] = qtdAdultos;
    if (qtdCriancas != null) data['qtdCriancas'] = qtdCriancas;
    if (observacoes != null) data['observacoes'] = observacoes;

    final response = await api.patch('/api/admin/attendance/$id', data);
    return Rsvp.fromJson(response);
  }
}
