import '../../../../core/network/api_client.dart';

class InvitationLine {
  final String id;
  final String identification;
  final int adults;
  final bool active;
  final bool responded;
  final bool? attending;
  final int children;

  InvitationLine.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        identification = json['identificacaoNoConvite'] as String,
        adults = json['quantidadeAdultos'] as int,
        active = json['ativo'] as bool,
        responded = json['respondida'] as bool? ?? false,
        attending =
            (json['rsvp'] as Map<String, dynamic>?)?['vaiComparecer'] as bool?,
        children =
            (json['rsvp'] as Map<String, dynamic>?)?['qtdCriancas'] as int? ??
                0;
}

class InvitationLinePageData {
  final List<InvitationLine> items;
  final int totalPages;
  final int total;

  const InvitationLinePageData(this.items, this.totalPages, this.total);
}

class InvitationLineRepository {
  final ApiClient api;
  InvitationLineRepository(this.api);

  Future<InvitationLinePageData> list(
      {int page = 1, String search = ''}) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'pageSize': '20',
      if (search.isNotEmpty) 'search': search,
    }).query;
    final response = await api.get('/api/admin/invitation-lines?$query')
        as Map<String, dynamic>;
    return InvitationLinePageData(
      (response['data'] as List)
          .map((item) => InvitationLine.fromJson(item as Map<String, dynamic>))
          .toList(),
      response['totalPages'] as int? ?? 1,
      response['total'] as int? ?? 0,
    );
  }

  Future<void> create(String identification, int adults) async {
    await api.post('/api/admin/invitation-lines', {
      'identificacaoNoConvite': identification,
      'quantidadeAdultos': adults,
    });
  }

  Future<void> update(InvitationLine line,
      {required int adults,
      required bool active,
      required String reason}) async {
    await api.put('/api/admin/invitation-lines/${line.id}', {
      'quantidadeAdultos': adults,
      'ativo': active,
      'motivo': reason,
    });
  }
}
