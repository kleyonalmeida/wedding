import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:wedding_app/core/network/api_client.dart';
import 'package:wedding_app/features/gifts/data/models/payment_return_order.dart';
import 'package:wedding_app/features/gifts/data/repositories/payment_return_repository.dart';

@GenerateNiceMocks([MockSpec<ApiClient>()])
import 'payment_return_repository_test.mocks.dart';

void main() {
  late PaymentReturnRepository repository;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = PaymentReturnRepository(apiClient: mockApiClient);
  });

  group('PaymentReturnRepository', () {
    test('getOrderDetails retorna PaymentReturnOrder quando API responde com sucesso', () async {
      final jsonResponse = {
        'id': '123',
        'status': 'Confirmed',
        'totalCents': 10000,
        'currency': 'BRL',
        'items': [],
        'senderName': 'Kleyon',
        'createdAtUtc': '2026-09-26T20:00:00Z',
      };

      when(mockApiClient.get('/api/gift-orders/123?token=abc'))
          .thenAnswer((_) async => jsonResponse);

      final result = await repository.getOrderDetails('123', 'abc');

      expect(result, isA<PaymentReturnOrder>());
      expect(result?.id, '123');
      expect(result?.status, 'Confirmed');
    });

    test('getOrderDetails lança exceção quando API falha', () async {
      when(mockApiClient.get('/api/gift-orders/123?token=abc'))
          .thenThrow(Exception('API error'));

      expect(
        () => repository.getOrderDetails('123', 'abc'),
        throwsException,
      );
    });
  });
}
