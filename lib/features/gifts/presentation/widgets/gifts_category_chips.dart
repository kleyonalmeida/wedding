import 'package:flutter/gestures.dart';
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

        final chips = ScrollConfiguration(
          behavior: const _FilterChipScrollBehavior(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < _categories.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  _CategoryChip(
                    label: _categories[index]['label']!,
                    selected: selectedCategory == _categories[index]['id'],
                    onSelected: () =>
                        onCategoryChanged(_categories[index]['id']!),
                  ),
                ],
              ],
            ),
          ),
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected
              ? Colors.transparent
              : theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _FilterChipScrollBehavior extends MaterialScrollBehavior {
  const _FilterChipScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
