import 'package:flutter/material.dart';
import '../../data/models/gift_product.dart';
import '../controllers/cart_controller.dart';
import 'cart_dialog.dart';
import 'checkout_dialog.dart';
import 'gifts_theme.dart';
import 'direct_pix_cart_notice.dart';

Future<void> showProductCheckout(BuildContext context, GiftProduct product,
    CartController cart, VoidCallback onCatalogChanged) async {
  if (!product.available) return;
  if (product.directPixOnly) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Theme(
        data: giftsTheme(context),
        child: AlertDialog(
          content: const Text(
            'Opaa, não pague por aqui não que tem imposto, aceitamos o pix, a chave é essa papai - 75991801820 :)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
            TextButton(
              onPressed: () {
                cart.addItem(product);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Adicionar ao carrinho'),
            ),
          ],
        ),
      ),
    );
    return;
  }
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
    var blockedByDirectPix = false;
    if (!context.mounted) return;
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => CartDialog(
            cartController: cart,
            onCheckout: () {
              if (cart.hasDirectPixOnly) {
                blockedByDirectPix = true;
              } else {
                proceed = true;
              }
              Navigator.of(dialogContext).pop();
            }));
    if (blockedByDirectPix && context.mounted) {
      showDirectPixCartNotice(context);
      return;
    }
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
