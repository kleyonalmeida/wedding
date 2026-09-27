import 'package:flutter/material.dart';

class GiftDedicationModal extends StatefulWidget {
  final String itemTitle;
  final String itemValue;
  final bool isCustomAmount;
  final VoidCallback onClose;
  final void Function(String name, String message, String? customAmount)
      onConfirm;
  final bool isLoading;
  final Widget? summary;
  final VoidCallback? onAddToCart;

  const GiftDedicationModal(
      {super.key,
      required this.itemTitle,
      required this.itemValue,
      required this.isCustomAmount,
      required this.onClose,
      required this.onConfirm,
      this.isLoading = false,
      this.summary,
      this.onAddToCart});

  @override
  State<GiftDedicationModal> createState() => _GiftDedicationModalState();
}

class _GiftDedicationModalState extends State<GiftDedicationModal> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _message = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _message.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isLoading || !_formKey.currentState!.validate()) return;
    widget.onConfirm(_name.text.trim(), _message.text.trim(),
        widget.isCustomAmount ? _amount.text.trim() : null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final padding = MediaQuery.sizeOf(context).width >= 768 ? 32.0 : 24.0;
    return PopScope(
        canPop: !widget.isLoading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child: Center(
              child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 512,
                maxHeight: (MediaQuery.sizeOf(context).height -
                        MediaQuery.viewInsetsOf(context).bottom -
                        32)
                    .clamp(0, double.infinity)),
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              elevation: 8,
              child: SingleChildScrollView(
                  child: Form(
                      key: _formKey,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                                color: colors.surfaceContainerLow,
                                padding: EdgeInsets.all(padding),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text('Presentear com Amor',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 12,
                                                    color: colors.secondary)),
                                            const SizedBox(height: 8),
                                            Text(widget.itemTitle,
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Playfair Display',
                                                    fontSize: 24,
                                                    color: colors.primary)),
                                            const SizedBox(height: 6),
                                            Text(
                                                'Sugerido: ${widget.itemValue}'),
                                          ])),
                                      IconButton(
                                          tooltip: 'Fechar',
                                          onPressed: widget.isLoading
                                              ? null
                                              : widget.onClose,
                                          icon: const Icon(Icons.close)),
                                    ])),
                            Padding(
                                padding: EdgeInsets.all(padding),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (widget.summary != null) ...[
                                        widget.summary!,
                                        const SizedBox(height: 20)
                                      ],
                                      const Text('Seu Nome / Família'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                          controller: _name,
                                          maxLength: 100,
                                          enabled: !widget.isLoading,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          validator: (value) => value
                                                      ?.trim()
                                                      .isNotEmpty ==
                                                  true
                                              ? null
                                              : 'Informe seu nome para o casal',
                                          decoration: _decoration(colors,
                                              'Ex: Tio Carlos e Família')),
                                      const SizedBox(height: 20),
                                      if (widget.isCustomAmount) ...[
                                        const Text(
                                            'Valor da Contribuição (R\$)'),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                            controller: _amount,
                                            enabled: !widget.isLoading,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            validator: (value) =>
                                                (double.tryParse((value ?? '')
                                                                .replaceAll(',',
                                                                    '.')) ??
                                                            0) >
                                                        0
                                                    ? null
                                                    : 'Informe um valor válido',
                                            decoration: _decoration(
                                                colors, 'Ex: 250,00')),
                                        const SizedBox(height: 20),
                                      ],
                                      const Text('Sua Mensagem aos Noivos'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                          controller: _message,
                                          enabled: !widget.isLoading,
                                          maxLength: 500,
                                          minLines: 3,
                                          maxLines: 6,
                                          decoration: _decoration(colors,
                                              'Escreva algumas palavras doces para aquecer nossos corações...')),
                                      const SizedBox(height: 20),
                                      Container(
                                          padding: const EdgeInsets.all(16),
                                          color: colors.surfaceContainerLow,
                                          child: Wrap(
                                              spacing: 12,
                                              runSpacing: 8,
                                              children: [
                                                Text(
                                                    'Ambiente seguro e afetivo',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: colors
                                                            .onSurfaceVariant)),
                                                const Text('PIX ou Cartão',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ])),
                                      const SizedBox(height: 24),
                                      Wrap(
                                          alignment: WrapAlignment.end,
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: [
                                            if (widget.onAddToCart != null)
                                              TextButton(
                                                  onPressed: widget.isLoading
                                                      ? null
                                                      : widget.onAddToCart,
                                                  child: const Text(
                                                      'Adicionar ao carrinho')),
                                            TextButton(
                                                onPressed: widget.isLoading
                                                    ? null
                                                    : widget.onClose,
                                                child: const Text('Voltar')),
                                            ElevatedButton(
                                                onPressed: widget.isLoading
                                                    ? null
                                                    : _submit,
                                                child: widget.isLoading
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth: 2))
                                                    : const Text(
                                                        'Confirmar Presente')),
                                          ]),
                                    ])),
                          ]))),
            ),
          )),
        ));
  }

  InputDecoration _decoration(ColorScheme colors, String hint) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: colors.surfaceContainerLow,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );
}
