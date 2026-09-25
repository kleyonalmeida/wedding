import 'package:flutter/material.dart';
import '../shell/admin_session_controller.dart';

class AdminFirstAccessPage extends StatefulWidget {
  const AdminFirstAccessPage({super.key});

  @override
  State<AdminFirstAccessPage> createState() => _AdminFirstAccessPageState();
}

class _AdminFirstAccessPageState extends State<AdminFirstAccessPage> {
  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    currentPassword.dispose();
    newPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final controller = AdminSessionProvider.of(context);
    try {
      setState(() => loading = true);
      controller.errorMessage = null;
      await controller.api.post('/api/admin/security/password', {
        'currentPassword': currentPassword.text,
        'newPassword': newPassword.text
      });
      currentPassword.clear();
      newPassword.clear();
      controller.requireLogin();
    } catch (_) {
      controller.errorMessage =
          'Não foi possível trocar a senha. Verifique os requisitos.';
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
                Text('Troque a senha inicial',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(controller.errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: currentPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Senha atual', border: OutlineInputBorder()),
                    enabled: !loading,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: newPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Nova senha', border: OutlineInputBorder()),
                    enabled: !loading,
                  ),
                ),
                FilledButton(
                  onPressed: loading ? null : _changePassword,
                  child: const Text('Salvar nova senha'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
