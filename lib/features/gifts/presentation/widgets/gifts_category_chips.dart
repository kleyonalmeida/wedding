import 'package:flutter/material.dart';

class GiftsCategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;

  const GiftsCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSearchChanged,
  });

  static const _categories = [
    {'id': 'todas', 'label': 'Todas as Lembranças'},
    {'id': 'luademel', 'label': 'Lua de Mel & Experiências'},
    {'id': 'lar', 'label': 'Nosso Novo Lar'},
    {'id': 'momentos', 'label': 'Jantares & Momentos'},
    {'id': 'cotas', 'label': 'Cotas Flexíveis'},
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;

        final searchField = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 288,
          ),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar lembrança ou cota...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        );

        final chips = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = selectedCategory == category['id'];
            final theme = Theme.of(context);

            return ChoiceChip(
              label: Text(category['label']!),
              selected: isSelected,
              onSelected: (_) => onCategoryChanged(category['id']!),
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
            );
          }).toList(),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              chips,
              const SizedBox(height: 16),
              searchField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: chips),
            const SizedBox(width: 24),
            searchField,
          ],
        );
      },
    );
  }
}
