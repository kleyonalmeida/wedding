import 'package:flutter/material.dart';
import 'textured_background.dart';
import '../../../../core/theme/app_colors.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 96.0, horizontal: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Text(
              'Sejam bem-vindos! Criamos este cantinho especial para dividir a nossa felicidade e os preparativos para o dia 26 de dezembro com vocês. A presença de cada um de vocês tornará o nosso grande dia ainda mais inesquecível!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 4.0,
                height: 3.0,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
