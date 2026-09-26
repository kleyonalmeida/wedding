import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class GiftsPixSection extends StatelessWidget {
  final VoidCallback onAddMessage;

  const GiftsPixSection({
    super.key,
    required this.onAddMessage,
  });

  void _copyPixKey(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: 'amor@kleyoneliandra.com.br'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chave PIX copiada!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        
        final content = [
          Expanded(
            flex: isDesktop ? 7 : 0,
            child: _buildLeftColumn(context),
          ),
          if (isDesktop) const SizedBox(width: 48) else const SizedBox(height: 32),
          Expanded(
            flex: isDesktop ? 5 : 0,
            child: _buildRightColumn(context),
          ),
        ];

        return Container(
          padding: EdgeInsets.all(isDesktop ? 48 : 32),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content.map((e) => e is Expanded ? e.child : e).toList(),
                ),
        );
      },
    );
  }

  Widget _buildLeftColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contribuição Afetiva Personalizada',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Celebre conosco da sua maneira',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 32,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sua presença é o nosso maior presente. Mas se desejar nos homenagear com uma contribuição flexível, criamos este espaço seguro para você.',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'amor@kleyoneliandra.com.br',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.primary),
                onPressed: () => _copyPixKey(context),
                tooltip: 'Copiar chave PIX',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onAddMessage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mail_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Enviar Recado com Presente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como funciona este carinho?',
            style: TextStyle(
              fontFamily: 'Bodoni Moda',
              fontSize: 24,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 24),
          _buildStep('01', 'Copie a chave PIX acima e realize a transferência no valor que desejar através do seu banco.'),
          const SizedBox(height: 16),
          _buildStep('02', 'Clique em "Enviar Recado com Presente" para nos deixar uma dedicatória especial.'),
          const SizedBox(height: 16),
          _buildStep('03', 'Sua mensagem será guardada com muito carinho em nosso livro de memórias!'),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
