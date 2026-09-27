class PaymentReturnOrderItem {
  final String giftId;
  final String name;
  final int unitPriceCents;
  final int quantity;

  PaymentReturnOrderItem({
    required this.giftId,
    required this.name,
    required this.unitPriceCents,
    required this.quantity,
  });

  factory PaymentReturnOrderItem.fromJson(Map<String, dynamic> json) {
    if (json['unitPriceCents'] is! int ||
        (json['unitPriceCents'] as int) < 0 ||
        json['quantity'] is! int ||
        (json['quantity'] as int) <= 0) {
      throw const FormatException('Invalid order item');
    }
    return PaymentReturnOrderItem(
      giftId: json['giftId'] as String,
      name: json['name'] as String,
      unitPriceCents: json['unitPriceCents'] as int,
      quantity: json['quantity'] as int,
    );
  }
}

class PaymentReturnOrder {
  final String id;
  final String status;
  final int totalCents;
  final String currency;
  final List<PaymentReturnOrderItem> items;
  final String senderName;
  final String? message;
  final DateTime createdAtUtc;
  final String? paymentMethod;
  final DateTime? confirmedAtUtc;
  final DateTime? receivedAtUtc;
  final String? checkoutUrl;

  PaymentReturnOrder({
    required this.id,
    required this.status,
    required this.totalCents,
    required this.currency,
    required this.items,
    required this.senderName,
    this.message,
    required this.createdAtUtc,
    this.paymentMethod,
    this.confirmedAtUtc,
    this.receivedAtUtc,
    this.checkoutUrl,
  });

  factory PaymentReturnOrder.fromJson(Map<String, dynamic> json) {
    if (json['totalCents'] is! int ||
        (json['totalCents'] as int) < 0 ||
        json['currency'] is! String ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(json['currency'] as String)) {
      throw const FormatException('Invalid order total or currency');
    }
    return PaymentReturnOrder(
      id: json['id'] as String,
      status: json['status'] as String,
      totalCents: json['totalCents'] as int,
      currency: json['currency'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) =>
              PaymentReturnOrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      senderName: json['senderName'] as String,
      message: json['message'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
      paymentMethod: json['paymentMethod'] as String?,
      confirmedAtUtc: json['confirmedAtUtc'] != null
          ? DateTime.parse(json['confirmedAtUtc'] as String).toUtc()
          : null,
      receivedAtUtc: json['receivedAtUtc'] != null
          ? DateTime.parse(json['receivedAtUtc'] as String).toUtc()
          : null,
      checkoutUrl: json['checkoutUrl'] as String?,
    );
  }
}
