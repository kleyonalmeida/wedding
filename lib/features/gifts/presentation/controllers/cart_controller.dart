import 'package:flutter/material.dart';
import '../../data/models/gift_product.dart';

class CartItem {
  final GiftProduct product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });
}

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (total, item) => total + item.quantity);

  double get totalValue => _items.fold(0, (total, item) => total + (item.product.currentPrice * item.quantity));

  void addItem(GiftProduct product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final existingIndex = _items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity = quantity;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
