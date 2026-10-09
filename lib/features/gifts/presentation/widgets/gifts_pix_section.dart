import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Área de contribuição livre por PIX. Só aparece com chave pública informada.
class GiftsPixSection extends StatelessWidget {
  final String? pixKey;
  final String? beneficiary;
  final VoidCallback? onAddMessage;

  const GiftsPixSection({
    super.key,
    this.pixKey,
    this.beneficiary,
    this.onAddMessage,
  });

  Future<void> _copy(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: pixKey!));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chave PIX copiada!')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível copiar a chave PIX.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pixKey?.trim().isNotEmpty != true) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1024;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 48 : 20,
            vertical: desktop ? 48 : 32,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                colors.surfaceContainerHigh.withValues(alpha: 0.55),
                colors.surfaceContainerLow,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 7, child: _lead(context, desktop)),
                    const SizedBox(width: 32),
                    Expanded(flex: 5, child: _stepsCard(context)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _lead(context, desktop),
                    const SizedBox(height: 32),
                    _stepsCard(context),
                  ],
                ),
        );
      },
    );
  }

  Widget _lead(BuildContext context, bool desktop) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.arrow_back_ios_new, size: 14, color: colors.secondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'CONTRIBUIÇÃO AFETIVA PERSONALIZADA',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                  color: colors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Deseja presentear com um valor personalizado?',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: desktop ? 36 : 30,
            height: 1.15,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '"O amor não se mede pelo que se tem, mas pelo que se compartilha com quem se ama." Você pode realizar uma transferência carinhosa direta via chave PIX dos noivos ou escolher a quantia que seu coração desejar.',
          style: TextStyle(
            fontFamily: 'Work Sans',
            fontSize: 16,
            height: 1.6,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _pixKeyCard(context),
            ElevatedButton(
              onPressed: onAddMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(Icons.edit_note, size: 18),
                  SizedBox(width: 8),
                  Text('ENVIAR RECADO COM PRESENTE',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pixKeyCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2, color: colors.secondary),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHAVE PIX (CASAMENTO)',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    letterSpacing: 0.6,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  pixKey!,
                  style: TextStyle(
                    fontFamily: 'Work Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
                if (beneficiary?.trim().isNotEmpty == true)
                  Text(
                    beneficiary!,
                    style: TextStyle(
                      fontFamily: 'Work Sans',
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar chave PIX',
            onPressed: () => _copy(context),
            color: colors.primary,
            icon: const Icon(Icons.content_copy, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _stepsCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified, color: colors.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como funciona este carinho?',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 18,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Transparência e significado',
                      style: TextStyle(
                        fontFamily: 'Work Sans',
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _step(
            context,
            '01.',
            'Você escolhe um momento simbólico ou valor à vontade.',
          ),
          const SizedBox(height: 14),
          _step(
            context,
            '02.',
            'Deixa uma mensagem sincera que será impressa em nosso livro de votos.',
          ),
          const SizedBox(height: 14),
          _step(
            context,
            '03.',
            'Sua homenagem se reverte em momentos autênticos vividos a dois.',
          ),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, String index, String text) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          index,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Work Sans',
              fontSize: 14,
              height: 1.45,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
