import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/payment_return_order.dart';
import '../../data/repositories/payment_return_repository.dart';

enum PaymentReturnState { loading, success, error, invalidLink, inaccessible }

class PaymentReturnController extends ChangeNotifier {
  final PaymentReturnRepository _repository;
  String _orderId = '';
  String? _token;
  int _generation = 0;
  bool _disposed = false;
  bool _busy = false;
  PaymentReturnState state = PaymentReturnState.loading;
  PaymentReturnOrder? order;
  bool isRefreshing = false;
  String? errorMessage;
  bool get isLoading => _busy;

  PaymentReturnController({PaymentReturnRepository? repository})
      : _repository = repository ?? PaymentReturnRepository();

  void init(String orderId, String? fragment) {
    if (_disposed) return;
    reset();
    _orderId = orderId;
    try {
      _token =
          fragment == null ? null : Uri.splitQueryString(fragment)['token'];
    } catch (_) {
      _token = null;
    }
    loadOrder();
  }

  Future<void> loadOrder() async {
    if (_disposed || _busy) return;
    if (!RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(_orderId) ||
        _token?.trim().isNotEmpty != true) {
      state = PaymentReturnState.invalidLink;
      notifyListeners();
      return;
    }
    final generation = _generation;
    _busy = true;
    isRefreshing = order != null;
    errorMessage = null;
    if (order == null) state = PaymentReturnState.loading;
    notifyListeners();
    try {
      final result = await _repository.getOrderDetails(_orderId, _token!);
      if (_disposed || generation != _generation) return;
      if (result == null) throw const ApiException(404);
      if (result.id.toLowerCase() != _orderId.toLowerCase()) {
        throw const FormatException('Unexpected order');
      }
      order = result;
      state = PaymentReturnState.success;
    } catch (e) {
      if (_disposed || generation != _generation) return;
      if (e is ApiException && (e.statusCode == 401 || e.statusCode == 404)) {
        order = null;
        state = PaymentReturnState.inaccessible;
        errorMessage =
            'Não foi possível acessar este pedido com o link informado.';
      } else {
        errorMessage = order == null
            ? 'Consulta indisponível. Tente novamente.'
            : 'Não foi possível atualizar. Os dados abaixo são da última consulta.';
        if (order == null) state = PaymentReturnState.error;
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _busy = false;
        isRefreshing = false;
        notifyListeners();
      }
    }
  }

  void reset() {
    _generation++;
    _orderId = '';
    _token = null;
    order = null;
    _busy = false;
    isRefreshing = false;
    errorMessage = null;
    state = PaymentReturnState.loading;
  }

  @override
  void dispose() {
    _disposed = true;
    reset();
    _repository.dispose();
    super.dispose();
  }
}
