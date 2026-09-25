import 'package:flutter/material.dart';
import '../shell/admin_session_controller.dart';

class AdminMfaPage extends StatefulWidget {
  final bool isEnrollment;
  const AdminMfaPage({super.key, required this.isEnrollment});

  @override
  State<AdminMfaPage> createState() => _AdminMfaPageState();
}

class _AdminMfaPageState extends State<AdminMfaPage> {
  final code = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> _verify({bool recovery = false}) async {
    final controller = AdminSessionProvider.of(context);
    try {
      setState(() => loading = true);
      controller.errorMessage = null;
      await controller.api.post(
          '/api/admin/auth/mfa/${recovery ? 'recovery' : 'verify'}',
          {'code': code.text.trim()});
      code.clear();
      await controller.loadSession();
    } catch (_) {
      controller.errorMessage = 'Código inválido.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _enroll() async {
    final controller = AdminSessionProvider.of(context);
    try {
      setState(() => loading = true);
      controller.errorMessage = null;
      final result =
          await controller.api.post('/api/admin/security/mfa/enroll', {});
      controller.setSharedKey(result['sharedKey'] as String);
    } catch (_) {
      controller.errorMessage =
          'Não foi possível iniciar a autenticação em duas etapas.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _confirmMfa() async {
    final controller = AdminSessionProvider.of(context);
    try {
      setState(() => loading = true);
      controller.errorMessage = null;
      final result = await controller.api
          .post('/api/admin/security/mfa/confirm', {'code': code.text.trim()});
      if (!mounted) return;

      final codes = (result['recoveryCodes'] as List?)?.join('\n') ?? '';
      await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
                title: const Text('Guarde os códigos de recuperação'),
                content: SelectableText(codes),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Guardei os códigos'))
                ],
              ));
      controller.setPhase(AdminSessionPhase.login);
      controller.setSharedKey(null);
      code.clear();
    } catch (_) {
      controller.errorMessage = 'Código inválido.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AdminSessionProvider.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    widget.isEnrollment
                        ? 'Configure a autenticação em duas etapas'
                        : 'Verificação em duas etapas',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(controller.errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                if (!widget.isEnrollment) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: code,
                      decoration: const InputDecoration(
                          labelText: 'Código do aplicativo ou recuperação',
                          border: OutlineInputBorder()),
                      enabled: !loading,
                    ),
                  ),
                  FilledButton(
                      onPressed: loading ? null : () => _verify(),
                      child: const Text('Verificar código')),
                  TextButton(
                      onPressed: loading ? null : () => _verify(recovery: true),
                      child: const Text('Usar código de recuperação')),
                ] else ...[
                  if (controller.sharedKey == null)
                    FilledButton(
                        onPressed: loading ? null : _enroll,
                        child: const Text('Gerar chave')),
                  if (controller.sharedKey != null) ...[
                    const Text(
                        'Adicione esta chave ao seu aplicativo autenticador:'),
                    const SizedBox(height: 8),
                    SelectableText(controller.sharedKey!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: code,
                        decoration: const InputDecoration(
                            labelText: 'Código de 6 dígitos',
                            border: OutlineInputBorder()),
                        enabled: !loading,
                      ),
                    ),
                    FilledButton(
                        onPressed: loading ? null : _confirmMfa,
                        child: const Text('Ativar proteção')),
                  ],
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
