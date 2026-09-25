import 'package:flutter/material.dart';

class AdminMetricGrid extends StatelessWidget {
  final List<Widget> children;

  const AdminMetricGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 500
                  ? 2
                  : 1;
          const gap = 14.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      );
}
