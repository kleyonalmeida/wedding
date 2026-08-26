import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gift_filter.dart';

class GiftSortSelector extends StatelessWidget {
  final int totalResults;
  final GiftSortOrder currentSort;
  final ValueChanged<GiftSortOrder> onSortChanged;

  const GiftSortSelector({
    super.key,
    required this.totalResults,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalResults > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Encontramos $totalResults produtos especiais para você',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSortButton(
              context,
              label: 'Mais Vendido',
              icon: Icons.favorite_border,
              order: GiftSortOrder.bestSeller,
            ),
            _buildSortButton(
              context,
              label: 'Maior Preço',
              icon: Icons.arrow_upward,
              order: GiftSortOrder.highestPrice,
            ),
            _buildSortButton(
              context,
              label: 'Menor Preço',
              icon: Icons.arrow_downward,
              order: GiftSortOrder.lowestPrice,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortButton(BuildContext context, {required String label, required IconData icon, required GiftSortOrder order}) {
    final isSelected = currentSort == order;
    return InkWell(
      onTap: () => onSortChanged(order),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}
