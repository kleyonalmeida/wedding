import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/gift_catalog_controller.dart';
import 'gift_filter_panel.dart';

class GiftFilterSheet extends StatelessWidget {
  final GiftCatalogController controller;

  const GiftFilterSheet({super.key, required this.controller});

  static Future<void> show(BuildContext context, GiftCatalogController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GiftFilterSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Playfair Display',
                  color: AppColors.dark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.dark),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: GiftFilterPanel(controller: controller),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('APLICAR FILTROS'),
          ),
        ],
      ),
    );
  }
}
