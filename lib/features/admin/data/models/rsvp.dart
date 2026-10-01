class Rsvp {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final bool vaiComparecer;
  final int qtdAdultos;
  final int qtdCriancas;
  final DateTime criadoEm;

  Rsvp({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.vaiComparecer,
    required this.qtdAdultos,
    required this.qtdCriancas,
    required this.criadoEm,
  });

  factory Rsvp.fromJson(Map<String, dynamic> json) {
    return Rsvp(
      id: json['id'].toString(),
      nome: json['identificacaoNoConvite'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      vaiComparecer: json['vaiComparecer'] as bool? ?? false,
      qtdAdultos: json['qtdAdultos'] as int? ?? 0,
      qtdCriancas: json['qtdCriancas'] as int? ?? 0,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
    );
  }
}

class AttendanceSummary {
  final int totalRespostas;
  final int confirmados;
  final int naoVao;
  final int totalAdultos;
  final int totalCriancas;
  final int totalPessoas;
  final int linhasPendentes;

  AttendanceSummary({
    required this.totalRespostas,
    required this.confirmados,
    required this.naoVao,
    required this.totalAdultos,
    required this.totalCriancas,
    required this.totalPessoas,
    required this.linhasPendentes,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalRespostas: (json['linhasConfirmadas'] as int? ?? 0) +
          (json['linhasRecusadas'] as int? ?? 0),
      confirmados: json['linhasConfirmadas'] as int? ?? 0,
      naoVao: json['linhasRecusadas'] as int? ?? 0,
      totalAdultos: json['totalAdultos'] as int? ?? 0,
      totalCriancas: json['totalCriancas'] as int? ?? 0,
      totalPessoas: json['totalPessoas'] as int? ?? 0,
      linhasPendentes: json['linhasPendentes'] as int? ?? 0,
    );
  }
}

class PaginatedRsvps {
  final List<Rsvp> data;
  final int totalPages;
  final int page;
  final int total;

  PaginatedRsvps(this.data, this.totalPages, this.page, this.total);
}
