import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/gift_catalog_controller.dart';

class GiftFilterPanel extends StatelessWidget {
  final GiftCatalogController controller;

  const GiftFilterPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FILTROS ATIVOS:',
                style: TextStyle(
                  color: AppColors.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (!controller.currentFilter.isEmpty)
                TextButton(
                  onPressed: controller.clearFilters,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Limpar todos os filtros',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAccordion(
            context: context,
            title: 'Presentes',
            items: controller.categories,
            selectedItems: controller.currentFilter.categories,
            onToggle: controller.toggleCategory,
          ),
        ],
      ),
    );
  }

  Widget _buildAccordion({
    required BuildContext context,
    required String title,
    required List<String> items,
    required List<String> selectedItems,
    required ValueChanged<String> onToggle,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.onPrimaryFixed,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Bodoni Moda',
          ),
        ),
        iconColor: AppColors.onPrimaryFixed,
        collapsedIconColor: AppColors.onPrimaryFixed,
        initiallyExpanded: true,
        children: items.map((item) {
          final isSelected = selectedItems.contains(item);
          return InkWell(
            onTap: () => onToggle(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggle(item),
                      activeColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.onPrimaryFixed,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
