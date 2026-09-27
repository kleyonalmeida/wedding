import 'package:flutter/material.dart';

class PaymentReturnHeading extends StatelessWidget {
  const PaymentReturnHeading({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 768;
    return Column(children: [
      Text('K&L',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 24,
              fontStyle: FontStyle.italic,
              letterSpacing: 2,
              color: colors.primary)),
      const SizedBox(height: 12),
      Text('Retorno do Pagamento',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: mobile ? 32 : 48,
              height: mobile ? 1.25 : 1.17,
              color: colors.onSurface)),
      const SizedBox(height: 12),
      ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Text(
              'A celebração da nossa união ganha ainda mais encanto com o seu carinho e presença.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, height: 1.75, color: colors.onSurfaceVariant))),
      const SizedBox(height: 40),
    ]);
  }
}
