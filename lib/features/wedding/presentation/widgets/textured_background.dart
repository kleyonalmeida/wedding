import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TexturedBackground extends StatelessWidget {
  final Widget child;

  const TexturedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        image: DecorationImage(
          image: AssetImage('assets/images/texture.png'),
          repeat: ImageRepeat.repeat,
          opacity: 0.7,
        ),
      ),
      child: child,
    );
  }
}
