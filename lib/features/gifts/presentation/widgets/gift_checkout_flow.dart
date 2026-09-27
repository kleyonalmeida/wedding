import 'package:flutter/material.dart';
import '../../data/models/gift_product.dart';
import '../controllers/cart_controller.dart';
import 'cart_dialog.dart';
import 'checkout_dialog.dart';
import 'gifts_theme.dart';

Future<void> showProductCheckout(BuildContext context, GiftProduct product,
    CartController cart, VoidCallback onCatalogChanged) async {
  if (!product.available) return;
  final selection = CartController()..addItem(product);
  try {
    if (!context.mounted) return;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Theme(
            data: giftsTheme(context),
            child: CheckoutDialog(
              cartController: selection,
              onCatalogChanged: onCatalogChanged,
              onBack: () => Navigator.of(dialogContext).pop(),
              onAddToCart: () {
                cart.addItem(product);
                Navigator.of(dialogContext).pop();
              },
            )));
  } finally {
    selection.dispose();
  }
}

Future<void> showGiftCart(BuildContext context, CartController cart,
    VoidCallback onCatalogChanged) async {
  while (context.mounted) {
    var proceed = false;
    if (!context.mounted) return;
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => CartDialog(
            cartController: cart,
            onCheckout: () {
              proceed = true;
              Navigator.of(dialogContext).pop();
            }));
    if (!proceed || !context.mounted) return;
    var back = false;
    if (!context.mounted) return;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Theme(
            data: giftsTheme(context),
            child: CheckoutDialog(
              cartController: cart,
              onCatalogChanged: onCatalogChanged,
              onBack: () {
                back = true;
                Navigator.of(dialogContext).pop();
              },
            )));
    if (!back) return;
  }
}
