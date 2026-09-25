import 'package:wedding_app/app_navigation.dart';
import 'package:flutter/material.dart';
import '../../data/models/audit_log.dart';
import '../../data/repositories/audit_repository.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_widgets.dart';

class AdminAuditDetailPage extends StatefulWidget {
  final String logId;
  const AdminAuditDetailPage({super.key, required this.logId});

  @override
  State<AdminAuditDetailPage> createState() => _AdminAuditDetailPageState();
}

class _AdminAuditDetailPageState extends State<AdminAuditDetailPage> {
  late Future<AuditLog> _log;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
        _log = AuditRepository(AdminSessionController.instance.api)
            .get(widget.logId);
      });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: AdminPageHeader(
              title: 'Detalhe do Log',
              subtitle: 'Auditoria',
              trailing: TextButton(
                onPressed: () => AppNavigation.replace(context, '/admin/logs'),
                child: const Text('Voltar aos logs'),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<AuditLog>(
              future: _log,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return snapshot.hasError
                      ? AdminErrorState(
                          message: 'Não foi possível carregar o log.',
                          onRetry: _load)
                      : const AdminLoadingState();
                }
                final log = snapshot.data!;
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field('ID', log.id),
                          _field('Data', log.timestampUtc.toLocal().toString()),
                          _field('Ação', log.action),
                          _field('Entidade', log.entityType),
                          _field('ID da entidade', log.entityId),
                          _field('Usuário', log.userId),
                          _field('Descrição', log.description),
                          _field('Sucesso', log.success ? 'Sim' : 'Não'),
                          _field('IP', log.ipAddress),
                          _field('Agente', log.userAgent),
                          _field('Correlação', log.correlationId),
                          _field('Valores anteriores',
                              AuditLog.prettyValues(log.oldValues)),
                          _field('Novos valores',
                              AuditLog.prettyValues(log.newValues)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _field(String label, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(value == null || value.isEmpty ? '—' : value),
          ],
        ),
      );
}
