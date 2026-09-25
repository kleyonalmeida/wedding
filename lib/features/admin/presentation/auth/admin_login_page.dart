import 'package:flutter/material.dart';
import '../shell/admin_session_controller.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final controller = AdminSessionProvider.of(context);
    try {
      setState(() {
        loading = true;
        controller.errorMessage = null;
      });
      final result = await controller.api.post('/api/admin/auth/login',
          {'username': email.text.trim(), 'password': password.text});
      password.clear();
      if (result['requiresTwoFactor'] == true) {
        controller.setPhase(AdminSessionPhase.verify);
      } else {
        await controller.loadSession();
      }
    } catch (_) {
      controller.errorMessage =
          'Não foi possível entrar. Confira os dados e tente novamente.';
      // We don't change phase, just show error
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
                Text('Acesso administrativo',
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
                    controller: email,
                    decoration: const InputDecoration(
                        labelText: 'Email', border: OutlineInputBorder()),
                    enabled: !loading,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Senha', border: OutlineInputBorder()),
                    enabled: !loading,
                  ),
                ),
                FilledButton(
                  onPressed: loading ? null : _login,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
