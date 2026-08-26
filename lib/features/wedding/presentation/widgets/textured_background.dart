import 'package:flutter/material.dart';

class TexturedBackground extends StatelessWidget {
  final Widget child;

  const TexturedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        image: DecorationImage(
          image: const AssetImage('assets/images/texture.png'),
          repeat: ImageRepeat.repeat,
          opacity: isDark ? 0.3 : 0.7,
        ),
      ),
      child: child,
    );
  }
}
