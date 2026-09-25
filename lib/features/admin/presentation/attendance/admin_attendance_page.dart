import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/models/rsvp.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_widgets.dart';
import '../widgets/admin_metric_card.dart';

class AdminAttendancePage extends StatefulWidget {
  final int initialPage;
  final String? initialSearch;
  final bool? initialStatus;
  const AdminAttendancePage(
      {super.key,
      this.initialPage = 1,
      this.initialSearch,
      this.initialStatus});

  @override
  State<AdminAttendancePage> createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  late AttendanceRepository _repository;

  Future<AttendanceSummary>? _summaryFuture;

  PaginatedRsvps? _data;
  bool _isLoading = false;
  String? _error;

  late int _page;
  String? _searchQuery;
  bool? _filterStatus; // null = all, true = confirmed, false = declined

  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _searchQuery = widget.initialSearch;
    _filterStatus = widget.initialStatus;
    _searchController.text = widget.initialSearch ?? '';
    _repository = AttendanceRepository(AdminSessionController.instance.api);
    _loadSummary();
    _loadData();
  }

  void _loadSummary() {
    setState(() {
      _summaryFuture = _repository.getSummary();
    });
  }

  Future<void> _loadData() async {
    final requestVersion = ++_requestVersion;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final result = await _repository.list(
        page: _page,
        search: _searchQuery,
        vaiComparecer: _filterStatus,
      );
      if (mounted && requestVersion == _requestVersion) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && requestVersion == _requestVersion) {
        setState(() {
          _error = 'Não foi possível carregar as presenças.';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (value.trim() == (_searchQuery ?? '')) return;
      Navigator.pushReplacementNamed(
          context, _route(page: 1, search: value.trim()));
    });
  }

  void _onFilterChanged(bool? value) {
    _searchDebounce?.cancel();
    Navigator.pushReplacementNamed(
        context,
        _route(
            page: 1,
            search: _searchController.text.trim(),
            status: value,
            preserveStatus: false));
  }

  String _route(
          {required int page,
          String? search,
          bool? status,
          bool preserveStatus = true}) =>
      Uri(
        path: '/admin/presenca',
        queryParameters: {
          'page': '$page',
          if ((search ?? _searchQuery)?.isNotEmpty == true)
            'search': search ?? _searchQuery!,
          if ((preserveStatus ? status ?? _filterStatus : status) != null)
            'status': '${preserveStatus ? status ?? _filterStatus : status}',
        },
      ).toString();

  Future<void> _openEditModal(Rsvp rsvp) async {
    final vaiComparecer = ValueNotifier<bool>(rsvp.vaiComparecer);
    final adultos = TextEditingController(text: rsvp.qtdAdultos.toString());
    final criancas = TextEditingController(text: rsvp.qtdCriancas.toString());
    final observacoes = TextEditingController(text: rsvp.observacoes ?? '');
    final motivo = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Editar Presença: ${rsvp.nome}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: vaiComparecer,
                      builder: (context, val, _) => SwitchListTile(
                        title: const Text('Vai comparecer?'),
                        value: val,
                        onChanged: (v) => vaiComparecer.value = v,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: adultos,
                            decoration: const InputDecoration(
                                labelText: 'Adultos',
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: criancas,
                            decoration: const InputDecoration(
                                labelText: 'Crianças',
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: observacoes,
                      decoration: const InputDecoration(
                          labelText: 'Observações',
                          border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: motivo,
                      decoration: const InputDecoration(
                          labelText: 'Motivo da alteração (obrigatório)',
                          border: OutlineInputBorder()),
                      validator: (v) => v!.trim().isEmpty
                          ? 'Obrigatório para auditoria'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setModalState(() => saving = true);
                        try {
                          await _repository.patch(
                            rsvp.id,
                            vaiComparecer: vaiComparecer.value,
                            qtdAdultos: int.tryParse(adultos.text) ?? 0,
                            qtdCriancas: int.tryParse(criancas.text) ?? 0,
                            observacoes: observacoes.text,
                            motivo: motivo.text,
                          );
                          if (context.mounted) Navigator.pop(context);
                          if (mounted) {
                            _loadData();
                            _loadSummary();
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Erro ao salvar edição.')));
                            setModalState(() => saving = false);
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(32),
          child: AdminPageHeader(
            title: 'Gestão de Presenças',
            subtitle: 'RSVP',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCards(),
                const SizedBox(height: 32),
                _buildListSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<AttendanceSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 180, child: AdminLoadingState());
        }
        if (snapshot.hasError) {
          return SizedBox(
              height: 180,
              child: AdminErrorState(message: 'Falha.', onRetry: _loadSummary));
        }

        final data = snapshot.data!;

        return LayoutBuilder(builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount:
                isDesktop ? 4 : (constraints.maxWidth > 600 ? 2 : 1),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: isDesktop ? 1.4 : 1.6,
            children: [
              AdminMetricCard(
                label: 'TOTAL DE RESPOSTAS',
                value: '${data.totalRespostas}',
                icon: Icons.mark_email_read,
                iconColor: Theme.of(context).colorScheme.primary,
              ),
              AdminMetricCard(
                label: 'CONFIRMADOS',
                value: '${data.confirmados}',
                icon: Icons.check_circle,
                iconColor: Colors.green,
              ),
              AdminMetricCard(
                label: 'RECUSADOS',
                value: '${data.naoVao}',
                icon: Icons.cancel,
                iconColor: Theme.of(context).colorScheme.error,
              ),
              AdminMetricCard(
                label: 'TOTAL DE PESSOAS',
                value: '${data.totalPessoas}',
                suffixText: '${data.totalAdultos} A / ${data.totalCriancas} C',
                icon: Icons.groups,
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildListSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
                builder: (context, constraints) => Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth < 600
                              ? constraints.maxWidth
                              : constraints.maxWidth - 220,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Buscar por nome ou e-mail',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: _onSearch,
                          ),
                        ),
                        DropdownMenu<bool?>(
                          initialSelection: _filterStatus,
                          label: const Text('Status'),
                          onSelected: _onFilterChanged,
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: null, label: 'Todos'),
                            DropdownMenuEntry(
                                value: true, label: 'Confirmados'),
                            DropdownMenuEntry(value: false, label: 'Recusados'),
                          ],
                        ),
                      ],
                    )),
          ),
          if (_isLoading && _data == null)
            const AdminLoadingState(message: 'Carregando lista...')
          else if (_error != null)
            AdminErrorState(message: _error!, onRetry: _loadData)
          else if (_data == null || _data!.data.isEmpty)
            const AdminEmptyState(message: 'Nenhuma resposta encontrada.')
          else ...[
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 650) {
                return Column(
                    children: _data!.data
                        .map((rsvp) => Card(
                              child: ListTile(
                                title: Text(rsvp.nome),
                                subtitle: Text(
                                    '${rsvp.email}\n${rsvp.vaiComparecer ? 'Confirmado' : 'Recusado'} • ${rsvp.qtdAdultos} adultos / ${rsvp.qtdCriancas} crianças'),
                                isThreeLine: true,
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () => Navigator.pushNamed(
                                    context, '/admin/presenca/${rsvp.id}'),
                              ),
                            ))
                        .toList());
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Convidado')),
                    DataColumn(label: Text('Telefone')),
                    DataColumn(label: Text('Adultos/Crianças')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Data')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rows: _data!.data.map((rsvp) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(rsvp.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              Text(rsvp.email,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        DataCell(Text(rsvp.telefone)),
                        DataCell(
                            Text('${rsvp.qtdAdultos} / ${rsvp.qtdCriancas}')),
                        DataCell(
                          Chip(
                            label: Text(
                                rsvp.vaiComparecer ? 'Confirmado' : 'Recusado'),
                            backgroundColor: rsvp.vaiComparecer
                                ? Colors.green.withValues(alpha: 0.2)
                                : Theme.of(context).colorScheme.errorContainer,
                            side: BorderSide.none,
                          ),
                        ),
                        DataCell(Text(
                            '${rsvp.criadoEm.day.toString().padLeft(2, '0')}/${rsvp.criadoEm.month.toString().padLeft(2, '0')}/${rsvp.criadoEm.year}')),
                        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            tooltip: 'Ver detalhes',
                            icon: const Icon(Icons.visibility),
                            onPressed: () => Navigator.pushNamed(
                                context, '/admin/presenca/${rsvp.id}'),
                          ),
                          IconButton(
                            tooltip: 'Editar Manualmente',
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditModal(rsvp),
                          ),
                        ])),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
            if (_data!.totalPages > 1)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _page > 1
                          ? () {
                              Navigator.pushNamed(
                                  context, _route(page: _page - 1));
                            }
                          : null,
                      child: const Text('Anterior'),
                    ),
                    const SizedBox(width: 16),
                    Text('Página $_page de ${_data!.totalPages}',
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _page < _data!.totalPages
                          ? () {
                              Navigator.pushNamed(
                                  context, _route(page: _page + 1));
                            }
                          : null,
                      child: const Text('Próxima'),
                    ),
                  ],
                ),
              ),
          ]
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
