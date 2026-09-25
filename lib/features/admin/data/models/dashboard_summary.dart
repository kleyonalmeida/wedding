class DashboardSummary {
  final DashboardRsvps rsvps;
  final DashboardProducts products;
  final DashboardOrders orders;
  final DashboardPayments payments;

  DashboardSummary({
    required this.rsvps,
    required this.products,
    required this.orders,
    required this.payments,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      rsvps: DashboardRsvps.fromJson(json['rsvps'] ?? {}),
      products: DashboardProducts.fromJson(json['products'] ?? {}),
      orders: DashboardOrders.fromJson(json['orders'] ?? {}),
      payments: DashboardPayments.fromJson(json['payments'] ?? {}),
    );
  }
}

class DashboardRsvps {
  final int total;
  final int confirmados;
  final int recusados;
  final int totalPessoas;

  DashboardRsvps({
    required this.total,
    required this.confirmados,
    required this.recusados,
    required this.totalPessoas,
  });

  factory DashboardRsvps.fromJson(Map<String, dynamic> json) {
    return DashboardRsvps(
      total: json['total'] as int? ?? 0,
      confirmados: json['confirmados'] as int? ?? 0,
      recusados: json['recusados'] as int? ?? 0,
      totalPessoas: json['totalPessoas'] as int? ?? 0,
    );
  }
}

class DashboardProducts {
  final int total;
  final int ativos;
  final int inativos;

  DashboardProducts({
    required this.total,
    required this.ativos,
    required this.inativos,
  });

  factory DashboardProducts.fromJson(Map<String, dynamic> json) {
    return DashboardProducts(
      total: json['total'] as int? ?? 0,
      ativos: json['ativos'] as int? ?? 0,
      inativos: json['inativos'] as int? ?? 0,
    );
  }
}

class DashboardOrders {
  final int paidOrders;

  DashboardOrders({required this.paidOrders});

  factory DashboardOrders.fromJson(Map<String, dynamic> json) {
    return DashboardOrders(
      paidOrders: json['paidOrders'] as int? ?? 0,
    );
  }
}

class DashboardPayments {
  final int pending;
  final int confirmed;
  final int cancelled;
  final int totalReceivedCents;

  DashboardPayments({
    required this.pending,
    required this.confirmed,
    required this.cancelled,
    required this.totalReceivedCents,
  });

  factory DashboardPayments.fromJson(Map<String, dynamic> json) {
    return DashboardPayments(
      pending: json['pending'] as int? ?? 0,
      confirmed: json['confirmed'] as int? ?? 0,
      cancelled: json['cancelled'] as int? ?? 0,
      totalReceivedCents: json['totalReceivedCents'] as int? ?? 0,
    );
  }
}

class DashboardActivity {
  final String id;
  final DateTime timestampUtc;
  final String action;
  final String entityType;
  final String description;

  DashboardActivity({
    required this.id,
    required this.timestampUtc,
    required this.action,
    required this.entityType,
    required this.description,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      id: json['id'].toString(),
      timestampUtc: DateTime.parse(json['timestampUtc'] as String),
      action: json['action'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
