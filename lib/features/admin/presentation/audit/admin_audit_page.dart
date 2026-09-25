import 'package:wedding_app/app_navigation.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/audit_repository.dart';
import '../../data/models/audit_log.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_widgets.dart';
import '../widgets/admin_responsive_records.dart';

class AdminAuditPage extends StatefulWidget {
  final int initialPage;
  const AdminAuditPage({super.key, this.initialPage = 1});

  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  late AuditRepository _repository;

  PaginatedAuditLogs? _data;
  bool _isLoading = false;
  String? _error;

  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _repository = AuditRepository(AdminSessionController.instance.api);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final result = await _repository.list(page: _page);
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar os logs de auditoria.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: AdminPageHeader(
            title: 'Logs de Auditoria',
            subtitle: 'Registro de atividades administrativas',
          ),
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _data == null) {
      return const AdminLoadingState(message: 'Carregando logs...');
    }

    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _loadData);
    }

    if (_data == null || _data!.data.isEmpty) {
      return const AdminEmptyState(
          message: 'Nenhum log de auditoria encontrado.');
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AdminResponsiveRecords(
                cards: _data!.data
                    .map((log) => Card(
                          child: ListTile(
                            title: Text(log.action),
                            subtitle: Text(
                                '${log.entityType} • ${log.timestampUtc.toLocal()}\n${log.userId ?? 'Sistema'}'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () => AppNavigation.go(
                                context, '/admin/logs/${log.id}'),
                          ),
                        ))
                    .toList(),
                table: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('Data')),
                    DataColumn(label: Text('Ação')),
                    DataColumn(label: Text('Entidade')),
                    DataColumn(label: Text('Responsável')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rows: _data!.data.map((log) {
                    final isDanger =
                        log.action.toUpperCase().contains('DELETE') ||
                            log.action.toUpperCase().contains('REMOVE');

                    return DataRow(
                      cells: [
                        DataCell(Text(
                            '${log.timestampUtc.toLocal().day.toString().padLeft(2, '0')}/${log.timestampUtc.toLocal().month.toString().padLeft(2, '0')} ${log.timestampUtc.toLocal().hour.toString().padLeft(2, '0')}:${log.timestampUtc.toLocal().minute.toString().padLeft(2, '0')}')),
                        DataCell(Chip(
                          label: Text(log.action,
                              style: theme.textTheme.labelSmall),
                          backgroundColor: isDanger
                              ? theme.colorScheme.errorContainer
                              : theme.colorScheme.surfaceContainerHigh,
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                        )),
                        DataCell(Text(
                            '${log.entityType} ${log.entityId == null ? "" : "(#${log.entityId!.substring(0, log.entityId!.length > 8 ? 8 : log.entityId!.length)})"}')),
                        DataCell(Text(log.userId ?? 'Sistema')),
                        DataCell(
                          IconButton(
                            tooltip: 'Ver Detalhes',
                            icon: const Icon(Icons.receipt_long),
                            onPressed: () => AppNavigation.go(
                                context, '/admin/logs/${log.id}'),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            // Pagination
            if (_data!.totalPages > 1)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _page > 1
                          ? () {
                              AppNavigation.go(
                                  context, '/admin/logs?page=${_page - 1}');
                            }
                          : null,
                      child: const Text('Anterior'),
                    ),
                    const SizedBox(width: 16),
                    Text('Página $_page de ${_data!.totalPages}',
                        style: theme.textTheme.labelSmall),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _page < _data!.totalPages
                          ? () {
                              AppNavigation.go(
                                  context, '/admin/logs?page=${_page + 1}');
                            }
                          : null,
                      child: const Text('Próxima'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
