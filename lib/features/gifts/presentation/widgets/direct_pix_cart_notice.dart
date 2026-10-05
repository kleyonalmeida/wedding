import 'package:flutter/material.dart';

OverlayEntry? _activeDirectPixNotice;

void showDirectPixCartNotice(BuildContext context) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final theme = Theme.of(context);
  _activeDirectPixNotice?.remove();
  _activeDirectPixNotice?.dispose();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) => SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(overlayContext).width - 32 < 420
                  ? MediaQuery.sizeOf(overlayContext).width - 32
                  : 420,
            ),
            child: Theme(
              data: theme,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Aviso sobre o carrinho',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Fechar aviso',
                            onPressed: () {
                              entry.remove();
                              entry.dispose();
                              if (identical(_activeDirectPixNotice, entry)) {
                                _activeDirectPixNotice = null;
                              }
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'O presente de preço elevado é uma brincadeira, não um produto de verdade. Se quiser mesmo presentear com esse valor, envie um Pix para 75991801820. Caso contrário, remova-o do carrinho e a compra seguirá normalmente. :)',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _activeDirectPixNotice = entry;
  overlay.insert(entry);
}
