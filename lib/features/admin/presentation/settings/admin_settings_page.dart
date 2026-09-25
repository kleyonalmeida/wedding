import 'package:flutter/material.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/models/app_setting.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_widgets.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  late SettingsRepository _repository;

  List<AppSetting>? _settings;
  bool _isLoading = false;
  String? _error;

  // Maps key to its editing controller
  final Map<String, TextEditingController> _controllers = {};
  // Maps key to saving state
  final Map<String, bool> _savingState = {};

  @override
  void initState() {
    super.initState();
    _repository = SettingsRepository(AdminSessionController.instance.api);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final settings = await _repository.get();

      for (var s in settings) {
        if (!_controllers.containsKey(s.key)) {
          _controllers[s.key] = TextEditingController(text: s.value ?? '');
          _savingState[s.key] = false;
        }
      }

      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar as configurações.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSetting(String key) async {
    setState(() => _savingState[key] = true);

    try {
      await _repository.patch({key: _controllers[key]!.text});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuração salva com sucesso.')),
        );
      }
      // Outros campos podem conter edições ainda não salvas.
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar configuração.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingState[key] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(32),
          child: AdminPageHeader(
            title: 'Configurações Globais',
            subtitle: 'Sistema',
          ),
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _settings == null) {
      return const AdminLoadingState(message: 'Carregando configurações...');
    }

    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _loadData);
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'As configurações abaixo refletem o banco de dados. Alterações aqui dependem de funcionalidades ativas no código para surtirem efeito visual no site.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_settings == null || _settings!.isEmpty)
            const AdminEmptyState(message: 'Nenhuma configuração exposta.')
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _settings!.map((setting) {
                    final isSaving = _savingState[setting.key] ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final compact = constraints.maxWidth < 600;
                        final gap = compact ? 0.0 : 24.0;
                        return Wrap(
                          spacing: gap,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: compact
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - gap) * 0.4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(setting.key,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  if (setting.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(setting.description!,
                                        style: theme.textTheme.bodySmall),
                                  ]
                                ],
                              ),
                            ),
                            SizedBox(
                              width: compact
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - gap) * 0.6,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controllers[setting.key],
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                        hintText: 'Valor vazio',
                                        filled: true,
                                        fillColor: theme.colorScheme.surface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  FilledButton.tonal(
                                    onPressed: isSaving
                                        ? null
                                        : () => _saveSetting(setting.key),
                                    child: isSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Text('Salvar'),
                                  ),
                                ],
                              ),
                            )
                          ],
                        );
                      }),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
