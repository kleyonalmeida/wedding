import 'package:flutter/material.dart';
import 'package:wedding_app/app_navigation.dart';

import '../../data/repositories/invitation_line_repository.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_widgets.dart';

class AdminAttendancePage extends StatefulWidget {
  final int initialPage;
  final String? initialSearch;
  final String? initialStatus;
  const AdminAttendancePage(
      {super.key,
      this.initialPage = 1,
      this.initialSearch,
      this.initialStatus});

  @override
  State<AdminAttendancePage> createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  late final InvitationLineRepository _repository;
  final _searchController = TextEditingController();
  InvitationLinePageData? _data;
  String? _error;
  bool _loading = false;
  late int _page;
  String? _filterStatus; // 'all', 'confirmed', 'declined', 'pending'

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _filterStatus = widget.initialStatus ?? 'all';
    _searchController.text = widget.initialSearch ?? '';
    _repository = InvitationLineRepository(AdminSessionController.instance.api);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repository.list(
          page: _page,
          search: _searchController.text.trim(),
          filterStatus: _filterStatus == 'all' ? null : _filterStatus);
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível carregar os convidados.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([InvitationLine? line]) async {
    final name = TextEditingController(text: line?.identification ?? '');
    final adults = TextEditingController(text: '${line?.adults ?? 1}');
    final reason = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool active = line?.active ?? true;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(line == null ? 'Cadastrar convidado' : 'Editar convidado'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: name,
                  readOnly: line != null,
                  decoration: const InputDecoration(
                    labelText: 'Identificação como no convite',
                    hintText: 'Jorge e Amanda',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe a identificação do convite.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: adults,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de adultos',
                    helperText: 'Jorge e Amanda = 2 adultos',
                  ),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                      ? 'Informe pelo menos um adulto.'
                      : null,
                ),
                if (line != null) ...[
                  SwitchListTile(
                    title: const Text('Convite ativo'),
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                  ),
                  TextFormField(
                    controller: reason,
                    decoration:
                        const InputDecoration(labelText: 'Motivo da alteração'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o motivo para auditoria.'
                        : null,
                  ),
                ],
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        if (line == null) {
                          await _repository.create(
                              name.text.trim(), int.parse(adults.text));
                        } else {
                          await _repository.update(line,
                              adults: int.parse(adults.text),
                              active: active,
                              reason: reason.text.trim());
                        }
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (mounted) await _load();
                      } catch (error) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Não foi possível salvar: $error')),
                          );
                          setDialogState(() => saving = false);
                        }
                      }
                    },
              child: Text(saving ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  String _status(InvitationLine line) {
    if (!line.active) return 'Inativo';
    if (!line.responded) return 'Pendente';
    return line.attending == true ? 'Confirmado' : 'Recusado';
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: AdminPageHeader(
              title: 'Presença / Convidados',
              subtitle: 'Gerencie a lista de convidados e suas respostas',
              trailing: FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Novo convidado'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar convite',
                      suffixIcon: IconButton(
                        tooltip: 'Buscar',
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _page = 1;
                          _load();
                        },
                      ),
                    ),
                    onSubmitted: (_) {
                      _page = 1;
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todos')),
                      DropdownMenuItem(value: 'confirmed', child: Text('Confirmados')),
                      DropdownMenuItem(value: 'declined', child: Text('Recusados')),
                      DropdownMenuItem(value: 'pending', child: Text('Pendentes')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value;
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading && _data == null
                ? const AdminLoadingState(message: 'Carregando lista...')
                : _error != null
                    ? AdminErrorState(message: _error!, onRetry: _load)
                    : _data == null || _data!.items.isEmpty
                        ? const AdminEmptyState(
                            message: 'Nenhum registro encontrado.')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _data!.items.length,
                            itemBuilder: (context, index) {
                              final line = _data!.items[index];
                              return Card(
                                child: ListTile(
                                  onTap: line.rsvpId != null
                                      ? () => AppNavigation.go(
                                          context, '/admin/presenca/${line.rsvpId}')
                                      : null,
                                  title: Text(line.identification),
                                  subtitle: Text(
                                    '${line.adultsConfirmed ?? line.adults} adulto(s) • ${_status(line)}'
                                    '${line.attending == true ? ' • ${line.children} criança(s)' : ''}',
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Editar convidado',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _openEditor(line),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          if (_data != null && _data!.totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: _page > 1
                      ? () {
                          _page--;
                          _load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_page de ${_data!.totalPages}'),
                IconButton(
                  tooltip: 'Próxima página',
                  onPressed: _page < _data!.totalPages
                      ? () {
                          _page++;
                          _load();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ]),
            ),
        ],
      );
}
