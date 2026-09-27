import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_app/features/gifts/data/models/payment_return_order.dart';

void main() {
  group('PaymentReturnOrder', () {
    test('fromJson com todos os campos presentes', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'status': 'Confirmed',
        'totalCents': 50000,
        'currency': 'BRL',
        'items': [
          {
            'giftId': 'gift-1',
            'name': 'Cota Paris',
            'unitPriceCents': 50000,
            'quantity': 1,
          }
        ],
        'senderName': 'Kleyon',
        'message': 'Parabéns!',
        'createdAtUtc': '2026-09-26T20:00:00Z',
        'paymentMethod': 'PIX',
        'confirmedAtUtc': '2026-09-26T20:05:00Z',
        'receivedAtUtc': '2026-09-26T20:05:00Z',
        'checkoutUrl': 'https://sandbox.asaas.com/checkout/123'
      };

      final order = PaymentReturnOrder.fromJson(json);

      expect(order.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(order.status, 'Confirmed');
      expect(order.totalCents, 50000);
      expect(order.currency, 'BRL');
      expect(order.items.length, 1);
      expect(order.items.first.name, 'Cota Paris');
      expect(order.senderName, 'Kleyon');
      expect(order.message, 'Parabéns!');
      expect(order.paymentMethod, 'PIX');
      expect(order.confirmedAtUtc, isNotNull);
      expect(order.receivedAtUtc, isNotNull);
      expect(order.checkoutUrl, 'https://sandbox.asaas.com/checkout/123');
    });

    test('fromJson com campos opcionais nulos e múltiplos itens', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'status': 'Pending',
        'totalCents': 75000,
        'currency': 'BRL',
        'items': [
          {
            'giftId': 'gift-1',
            'name': 'Cota Paris',
            'unitPriceCents': 50000,
            'quantity': 1,
          },
          {
            'giftId': 'gift-2',
            'name': 'Jantar',
            'unitPriceCents': 25000,
            'quantity': 1,
          }
        ],
        'senderName': 'Liandra',
        'message': null,
        'createdAtUtc': '2026-09-26T20:00:00Z',
        'paymentMethod': null,
        'confirmedAtUtc': null,
        'receivedAtUtc': null,
        'checkoutUrl': null
      };

      final order = PaymentReturnOrder.fromJson(json);

      expect(order.message, isNull);
      expect(order.paymentMethod, isNull);
      expect(order.confirmedAtUtc, isNull);
      expect(order.receivedAtUtc, isNull);
      expect(order.checkoutUrl, isNull);
      expect(order.items.length, 2);
    });
  });
}
