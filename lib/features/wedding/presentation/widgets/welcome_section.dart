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
              'CRIAMOS ESSE SITE PARA COMPARTILHAR COM VOCÊS OS DETALHES DA ORGANIZAÇÃO DO NOSSO CASAMENTO. ESTAMOS MUITO FELIZES E CONTAMOS COM A SUA PRESENÇA NO NOSSO GRANDE DIA!',
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
