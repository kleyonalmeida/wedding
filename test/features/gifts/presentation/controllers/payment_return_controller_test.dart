import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wedding_app/features/gifts/data/models/payment_return_order.dart';
import 'package:wedding_app/features/gifts/presentation/controllers/payment_return_controller.dart';
import 'package:wedding_app/features/gifts/data/repositories/payment_return_repository.dart';

class MockPaymentReturnRepository extends Mock
    implements PaymentReturnRepository {
  @override
  Future<PaymentReturnOrder?> getOrderDetails(String? id, String? token) {
    return super.noSuchMethod(
      Invocation.method(#getOrderDetails, [id, token]),
      returnValue: Future.value(null),
      returnValueForMissingStub: Future.value(null),
    );
  }
}

void main() {
  late MockPaymentReturnRepository mockRepository;
  late PaymentReturnController controller;

  setUp(() {
    mockRepository = MockPaymentReturnRepository();
    controller = PaymentReturnController(repository: mockRepository);
  });

  group('PaymentReturnController', () {
    test('estado inicial deve ser loading', () {
      expect(controller.state, PaymentReturnState.loading);
    });

    test('init com token inválido vai para invalidLink sem chamar API',
        () async {
      controller.init('11111111-1111-4111-8111-111111111111', null);
      expect(controller.state, PaymentReturnState.invalidLink);
      verifyNever(mockRepository.getOrderDetails(any, any));
    });

    test('init com sucesso carrega dados e muda para success', () async {
      final order = PaymentReturnOrder(
        id: '11111111-1111-4111-8111-111111111111',
        status: 'Confirmed',
        totalCents: 50000,
        currency: 'BRL',
        items: [],
        senderName: 'Teste',
        createdAtUtc: DateTime.now(),
      );

      when(mockRepository.getOrderDetails(
              '11111111-1111-4111-8111-111111111111', 'abc'))
          .thenAnswer((_) async => order);

      controller.init('11111111-1111-4111-8111-111111111111', 'token=abc');

      expect(controller.state, PaymentReturnState.loading);

      await Future.delayed(Duration.zero); // Wait microtask

      expect(controller.state, PaymentReturnState.success);
      expect(controller.order, order);
    });

    test('erro transiente na atualização mantém dados anteriores e exibe erro',
        () async {
      final order = PaymentReturnOrder(
        id: '11111111-1111-4111-8111-111111111111',
        status: 'Pending',
        totalCents: 50000,
        currency: 'BRL',
        items: [],
        senderName: 'Teste',
        createdAtUtc: DateTime.now(),
      );

      when(mockRepository.getOrderDetails(
              '11111111-1111-4111-8111-111111111111', 'abc'))
          .thenAnswer((_) async => order);

      controller.init('11111111-1111-4111-8111-111111111111', 'token=abc');
      await Future.delayed(Duration.zero);
      expect(controller.state, PaymentReturnState.success);

      // Simular refresh falhando
      when(mockRepository.getOrderDetails(
              '11111111-1111-4111-8111-111111111111', 'abc'))
          .thenThrow(Exception('Rede falhou'));

      await controller.loadOrder();

      expect(
          controller.state,
          PaymentReturnState
              .success); // Mantém estado sucesso pois order != null
      expect(controller.order, isNotNull);
      expect(controller.errorMessage, isNotNull);
    });
  });
}
