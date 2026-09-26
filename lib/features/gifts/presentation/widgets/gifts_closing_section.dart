import 'package:flutter/material.dart';

class GiftsClosingSection extends StatelessWidget {
  const GiftsClosingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        key: const Key('closing_section_constraints'),
        constraints: const BoxConstraints(maxWidth: 672),
        child: Padding(
          key: const Key('closing_section_padding'),
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Memórias que duram para sempre',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Bodoni Moda',
                  fontSize: 36,
                  height: 44 / 36,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Agradecemos profundamente por sonhar este novo capítulo ao nosso lado. Cada gesto de carinho ilumina ainda mais o caminho até o nosso "Sim".',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Work Sans',
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
