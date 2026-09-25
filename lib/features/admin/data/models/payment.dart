class PaymentListItem {
  final String id;
  final String? gatewayPaymentId;
  final String status;
  final int amountCents;
  final DateTime createdAtUtc;
  final String? senderName;

  PaymentListItem({
    required this.id,
    this.gatewayPaymentId,
    required this.status,
    required this.amountCents,
    required this.createdAtUtc,
    this.senderName,
  });

  factory PaymentListItem.fromJson(Map<String, dynamic> json) {
    return PaymentListItem(
      id: json['id'].toString(),
      gatewayPaymentId: json['gatewayPaymentId']?.toString(),
      status: json['status']?.toString() ?? 'Unknown',
      amountCents: json['amountCents'] as int? ?? 0,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      senderName: json['senderName']?.toString(),
    );
  }
}

class PaginatedPayments {
  final List<PaymentListItem> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedPayments(this.items, this.total, this.page, this.pageSize);
}

class PaymentDetail {
  final String id;
  final String? gatewayPaymentId;
  final String status;
  final int amountCents;
  final int netCents;
  final String billingType;
  final DateTime createdAtUtc;
  final DateTime? confirmedAtUtc;
  final DateTime? receivedAtUtc;
  final PaymentOrder? order;

  PaymentDetail({
    required this.id,
    this.gatewayPaymentId,
    required this.status,
    required this.amountCents,
    required this.netCents,
    required this.billingType,
    required this.createdAtUtc,
    this.confirmedAtUtc,
    this.receivedAtUtc,
    this.order,
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      id: json['id'].toString(),
      gatewayPaymentId: json['gatewayPaymentId']?.toString(),
      status: json['status']?.toString() ?? 'Unknown',
      amountCents: json['amountCents'] as int? ?? 0,
      netCents: json['netCents'] as int? ?? 0,
      billingType: json['billingType']?.toString() ?? '',
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      confirmedAtUtc: json['confirmedAtUtc'] != null
          ? DateTime.parse(json['confirmedAtUtc'] as String)
          : null,
      receivedAtUtc: json['receivedAtUtc'] != null
          ? DateTime.parse(json['receivedAtUtc'] as String)
          : null,
      order:
          json['order'] != null ? PaymentOrder.fromJson(json['order']) : null,
    );
  }
}

class PaymentOrder {
  final String id;
  final String senderName;
  final String? message;
  final List<PaymentOrderItem> items;

  PaymentOrder({
    required this.id,
    required this.senderName,
    this.message,
    required this.items,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: json['id'].toString(),
      senderName: json['senderName']?.toString() ?? 'Desconhecido',
      message: json['message']?.toString(),
      items: (json['items'] as List?)
              ?.map((e) => PaymentOrderItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PaymentOrderItem {
  final int quantity;
  final String name;
  final int priceCents;

  PaymentOrderItem({
    required this.quantity,
    required this.name,
    required this.priceCents,
  });

  factory PaymentOrderItem.fromJson(Map<String, dynamic> json) {
    return PaymentOrderItem(
      quantity: json['quantity'] as int? ?? 1,
      name: json['name']?.toString() ?? '',
      priceCents: json['priceCents'] as int? ?? 0,
    );
  }
}

class PaymentEvent {
  final String id;
  final String eventType;
  final String status;
  final DateTime receivedAtUtc;
  final DateTime? processedAtUtc;
  final String? errorCode;

  PaymentEvent({
    required this.id,
    required this.eventType,
    required this.status,
    required this.receivedAtUtc,
    this.processedAtUtc,
    this.errorCode,
  });

  factory PaymentEvent.fromJson(Map<String, dynamic> json) {
    return PaymentEvent(
      id: json['id'].toString(),
      eventType: json['eventType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      receivedAtUtc: DateTime.parse(json['receivedAtUtc'] as String),
      processedAtUtc: json['processedAtUtc'] != null
          ? DateTime.parse(json['processedAtUtc'] as String)
          : null,
      errorCode: json['errorCode']?.toString(),
    );
  }
}
