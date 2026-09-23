import 'package:flutter/material.dart';

class TexturedBackground extends StatelessWidget {
  final Widget child;
  final String textureAssetPath;
  final BoxFit? textureFit;

  const TexturedBackground({
    super.key,
    required this.child,
    this.textureAssetPath = 'assets/images/texture.png',
    this.textureFit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        image: DecorationImage(
          image: AssetImage(textureAssetPath),
          repeat: ImageRepeat.repeat,
          fit: textureFit,
          opacity: isDark ? 0.3 : 0.7,
        ),
      ),
      child: child,
    );
  }
}
