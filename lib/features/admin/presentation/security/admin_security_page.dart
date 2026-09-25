import 'package:flutter/material.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';

class AdminSecurityPage extends StatefulWidget {
  const AdminSecurityPage({super.key});

  @override
  State<AdminSecurityPage> createState() => _AdminSecurityPageState();
}

class _AdminSecurityPageState extends State<AdminSecurityPage> {
  final _api = AdminSessionController.instance.api;

  bool _isRevoking = false;

  // Para troca de senha
  final _formKey = GlobalKey<FormState>();
  final _oldPass = TextEditingController();
  final _newPass = TextEditingController();
  bool _isChangingPassword = false;
  String? _passError;

  Future<void> _revokeSessions() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar todas as sessões?'),
        content: const Text(
            'Isso fará com que todas as suas sessões ativas (incluindo esta) sejam encerradas imediatamente. Você precisará fazer login novamente. Deseja continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Revogar')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isRevoking = true);
      try {
        await _api.post('/api/admin/security/sessions/revoke', {});
        AdminSessionController.instance.requireLogin();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao revogar sessões.')),
          );
          setState(() => _isRevoking = false);
        }
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isChangingPassword = true;
      _passError = null;
    });

    try {
      await _api.post('/api/admin/security/password', {
        'currentPassword': _oldPass.text,
        'newPassword': _newPass.text,
      });

      if (mounted) AdminSessionController.instance.requireLogin();
    } catch (_) {
      if (mounted) {
        setState(() =>
            _passError = 'Falha ao alterar senha. Verifique sua senha atual.');
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(32),
          child: AdminPageHeader(
            title: 'Segurança',
            subtitle: 'Controle de Acesso e Sessões',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 800;
              final gap = compact ? 0.0 : 32.0;
              return Wrap(
                spacing: gap,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: compact
                        ? constraints.maxWidth
                        : (constraints.maxWidth - gap) * 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ALTERAR SENHA',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color:
                                                  theme.colorScheme.outline)),
                                  const SizedBox(height: 24),
                                  if (_passError != null)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Text(_passError!,
                                          style: TextStyle(
                                              color: theme.colorScheme.error)),
                                    ),
                                  TextFormField(
                                    controller: _oldPass,
                                    decoration: const InputDecoration(
                                        labelText: 'Senha Atual',
                                        border: OutlineInputBorder()),
                                    obscureText: true,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Obrigatório' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _newPass,
                                    decoration: const InputDecoration(
                                        labelText: 'Nova Senha',
                                        border: OutlineInputBorder()),
                                    obscureText: true,
                                    validator: (v) => v!.length < 8
                                        ? 'Mínimo de 8 caracteres'
                                        : null,
                                  ),
                                  const SizedBox(height: 24),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton(
                                      onPressed: _isChangingPassword
                                          ? null
                                          : _changePassword,
                                      child: _isChangingPassword
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white))
                                          : const Text('Atualizar Senha'),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: compact
                        ? constraints.maxWidth
                        : (constraints.maxWidth - gap) * 0.4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AUTENTICAÇÃO DE DOIS FATORES',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.outline)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.shield,
                                        color: Colors.green, size: 32),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Status do MFA',
                                              style: theme.textTheme.bodySmall),
                                          Text('Ativo e Protegido',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'A habilitação do MFA é feita no primeiro acesso ao painel.',
                                  style: theme.textTheme.bodySmall,
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SESSÕES ATIVAS',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.outline)),
                                const SizedBox(height: 16),
                                const Text(
                                    'Encerre o acesso deste usuário em todos os dispositivos.'),
                                const SizedBox(height: 24),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                    side: BorderSide(
                                        color: theme.colorScheme.error),
                                  ),
                                  onPressed:
                                      _isRevoking ? null : _revokeSessions,
                                  icon: _isRevoking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.phonelink_erase),
                                  label: const Text('Revogar Todas as Sessões'),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              );
            }),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _oldPass.dispose();
    _newPass.dispose();
    super.dispose();
  }
}
