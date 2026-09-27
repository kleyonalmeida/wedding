import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Only render when the public key, beneficiary and real contribution flow exist.
class GiftsPixSection extends StatelessWidget {
  final String? pixKey;
  final String? beneficiary;
  final VoidCallback? onAddMessage;
  const GiftsPixSection(
      {super.key, this.pixKey, this.beneficiary, this.onAddMessage});

  Future<void> _copy(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: pixKey!));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Chave PIX copiada!')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível copiar a chave PIX.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pixKey?.trim().isNotEmpty != true ||
        beneficiary?.trim().isNotEmpty != true ||
        onAddMessage == null) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 1024;
      final left =
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Contribuição Afetiva Personalizada',
            style: TextStyle(fontSize: 12, color: colors.secondary)),
        const SizedBox(height: 16),
        Text('Deseja presentear com um valor personalizado?',
            style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: desktop ? 36 : 30,
                color: colors.primary)),
        const SizedBox(height: 16),
        const Text(
            'Você pode realizar uma transferência direta via PIX ou escolher uma contribuição com dedicatória.'),
        const SizedBox(height: 24),
        Container(
            padding: const EdgeInsets.all(16),
            color: colors.surface,
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('CHAVE PIX (CASAMENTO)'),
                    SelectableText(pixKey!),
                    Text(beneficiary!),
                  ])),
              IconButton(
                  tooltip: 'Copiar chave PIX',
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy))
            ])),
        const SizedBox(height: 20),
        ElevatedButton(
            onPressed: onAddMessage,
            child: const Text('Enviar Recado com Presente')),
      ]);
      final right = Container(
          padding: const EdgeInsets.all(24),
          color: colors.surface,
          child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Como funciona este carinho?',
                    style: TextStyle(
                        fontFamily: 'Playfair Display', fontSize: 20)),
                SizedBox(height: 16),
                Text('01'),
                Text('Escolha um presente simbólico ou contribuição.'),
                SizedBox(height: 12),
                Text('02'),
                Text('Deixe uma mensagem aos noivos.'),
                SizedBox(height: 12),
                Text('03'),
                Text(
                    'Copiar a chave PIX não confirma o pagamento nem registra uma dedicatória.'),
              ]));
      return Container(
          padding: EdgeInsets.all(desktop ? 48 : 32),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(colors: [
                colors.surfaceContainer,
                colors.surfaceContainerLow
              ])),
          child: desktop
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 7, child: left),
                  const SizedBox(width: 32),
                  Expanded(flex: 5, child: right),
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [left, const SizedBox(height: 32), right]));
    });
  }
}
