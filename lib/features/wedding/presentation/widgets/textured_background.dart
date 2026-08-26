import 'package:flutter/material.dart';

class TexturedBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const TexturedBackground({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDdtX-w8qU5A1udGxq34wcEslQ4xEY9DBByDDmTJuiNq7idXrn-EXdtVDv6Jp_nkT2agY__WjEu3mK72xU1kAgfQ010L1zRgpWc0Jy8ZSXm7kfu3cw62_PZL5-kO6stgI431UxiQUxL13Mhi1y7ycx8C3HrGZRMbKjsTkkLwjB0psRz4HTsMQdAvoUeiB6ZzohY7MiD_UaA-Cn0w0xLCyTn-AMTSmDTTAYFjeLqw7jb8XR4F4TVTbl2L_9IUSgMb3BwdA',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
