import 'package:flutter/material.dart';

class AdminResponsiveRecords extends StatelessWidget {
  final Widget table;
  final List<Widget> cards;

  const AdminResponsiveRecords(
      {super.key, required this.table, required this.cards});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return ListView(
              padding: const EdgeInsets.all(12),
              children: cards,
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: table,
            ),
          );
        },
      );
}
