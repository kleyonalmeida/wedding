import '../../../../core/network/api_client.dart';

class InvitationLine {
  final String id;
  final String? rsvpId;
  final String identification;
  final int adults;
  final bool active;
  final bool responded;
  final bool? attending;
  final int childrenLimit;
  final int children;
  final int? adultsConfirmed;

  InvitationLine.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        rsvpId = json['rsvpId'] as String?,
        identification = json['identificacaoNoConvite'] as String,
        adults = json['quantidadeAdultos'] as int,
        active = json['ativo'] as bool,
        responded = json['rsvpId'] != null,
        attending = json['vaiComparecer'] as bool?,
        childrenLimit = json['quantidadeCriancas'] as int? ?? 0,
        children = json['qtdCriancasConfirmadas'] as int? ?? 0,
        adultsConfirmed = json['qtdAdultosConfirmados'] as int?;
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
      {int page = 1, String search = '', String? filterStatus}) async {
    final Map<String, String> queryParams = {
      'page': '$page',
      'pageSize': '15',
    };
    if (search.isNotEmpty) queryParams['search'] = search;
    
    if (filterStatus == 'confirmed') {
      queryParams['respondida'] = 'true';
      queryParams['vaiComparecer'] = 'true';
    } else if (filterStatus == 'declined') {
      queryParams['respondida'] = 'true';
      queryParams['vaiComparecer'] = 'false';
    } else if (filterStatus == 'pending') {
      queryParams['pendente'] = 'true';
    }

    final query = Uri(queryParameters: queryParams).query;
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

  Future<void> create(String identification, int adults, [int childrenLimit = 0]) async {
    await api.post('/api/admin/invitation-lines', {
      'identificacaoNoConvite': identification,
      'quantidadeAdultos': adults,
      'quantidadeCriancas': childrenLimit,
    });
  }

  Future<void> update(InvitationLine line,
      {String? identification,
      required int adults,
      int? childrenLimit,
      required bool active,
      required String reason}) async {
    final data = <String, dynamic>{
      'quantidadeAdultos': adults,
      'ativo': active,
      'motivo': reason,
    };
    if (childrenLimit != null) {
      data['quantidadeCriancas'] = childrenLimit;
    }
    if (identification != null) {
      data['identificacaoNoConvite'] = identification;
    }
    await api.put('/api/admin/invitation-lines/${line.id}', data);
  }
}
