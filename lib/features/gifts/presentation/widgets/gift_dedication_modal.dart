import 'package:flutter/material.dart';

class GiftDedicationModal extends StatefulWidget {
  final String itemTitle;
  final String itemValue;
  final bool isCustomAmount;
  final VoidCallback onClose;
  final void Function(String name, String message, String? customAmount) onConfirm;

  const GiftDedicationModal({
    super.key,
    required this.itemTitle,
    required this.itemValue,
    required this.isCustomAmount,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  State<GiftDedicationModal> createState() => _GiftDedicationModalState();
}

class _GiftDedicationModalState extends State<GiftDedicationModal> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    widget.onConfirm(
      _nameController.text,
      _messageController.text,
      widget.isCustomAmount ? _amountController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 512),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // margens mínimas 16 px
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            elevation: 8,
            child: SingleChildScrollView( // Conteúdo rolável com teclado aberto
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Header
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0), // padding 24/32 px
                    color: theme.colorScheme.surfaceContainerLow ?? theme.colorScheme.surfaceContainerHighest,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Presentear com Amor',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.itemTitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.itemValue.startsWith('Sugerido:') || widget.itemValue.startsWith('Valor')
                                    ? widget.itemValue
                                    : 'Sugerido: ${widget.itemValue}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),

                  // Modal Form
                  Padding(
                    padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name Field
                        Text(
                          'Seu Nome / Família',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Ex: Tio Carlos e Família',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Custom Amount Field
                        if (widget.isCustomAmount) ...[
                          Text(
                            'Valor da Contribuição (R\$)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Ex: 250',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerLow,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Message Field
                        Text(
                          'Sua Mensagem aos Noivos',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Escreva algumas palavras doces para aquecer nossos corações...',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.lock, size: 16, color: theme.colorScheme.secondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Ambiente seguro e afetivo',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'PIX ou Cartão',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Actions
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            TextButton(
                              onPressed: widget.onClose,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                foregroundColor: theme.colorScheme.onSurfaceVariant,
                              ),
                              child: const Text('Voltar'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.send, size: 18),
                              label: const Text('Confirmar Presente'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
