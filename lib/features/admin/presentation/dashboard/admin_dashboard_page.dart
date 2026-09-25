import 'package:flutter/material.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/dashboard_summary.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_metric_card.dart';
import '../widgets/admin_state_widgets.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late DashboardRepository _repository;

  Future<DashboardSummary>? _summaryFuture;
  Future<List<dynamic>>? _attendanceFuture;
  Future<List<dynamic>>? _paymentsFuture;
  Future<List<DashboardActivity>>? _activityFuture;

  @override
  void initState() {
    super.initState();
    _repository = DashboardRepository(AdminSessionController.instance.api);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _summaryFuture = _repository.getSummary();
      _attendanceFuture = _repository.getRecentAttendance();
      _paymentsFuture = _repository.getRecentPayments();
      _activityFuture = _repository.getActivity(limit: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBanner(context),
          const SizedBox(height: 32),
          _buildSummaryCards(),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 65,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRecentAttendance(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 35,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRecentPayments(),
                          const SizedBox(height: 32),
                          _buildRecentActivity(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Mobile / Tablet layout
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRecentAttendance(),
                  const SizedBox(height: 32),
                  _buildRecentPayments(),
                  const SizedBox(height: 32),
                  _buildRecentActivity(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: theme.colorScheme.secondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'PAINEL NUPCIAL EXCLUSIVO',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bem-vindo de volta, Kleyon & Liandra',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Visão geral da organização e métricas do seu casamento',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin/produtos/novo'),
                icon: const Icon(Icons.add),
                label: const Text('Novo Produto'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin/presenca'),
                icon: const Icon(Icons.people),
                label: const Text('Ver Presença'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin/pagamentos'),
                icon: const Icon(Icons.payments),
                label: const Text('Ver Pagamentos'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<DashboardSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 180, child: AdminLoadingState());
        }
        if (snapshot.hasError) {
          return SizedBox(
              height: 180,
              child: AdminErrorState(
                  message: 'Falha ao carregar resumo.', onRetry: _loadData));
        }

        final data = snapshot.data!;

        final rsvpProg = data.rsvps.total == 0
            ? 0.0
            : (data.rsvps.confirmados / data.rsvps.total);

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
                label: 'PRESENÇA CONFIRMADA',
                value: '${data.rsvps.totalPessoas}',
                suffixText: 'pessoas',
                icon: Icons.how_to_reg,
                progress: rsvpProg,
                progressLabel: 'Respostas recebidas',
                progressValue: '${(rsvpProg * 100).toStringAsFixed(1)}%',
              ),
              AdminMetricCard(
                label: 'ARRECADAÇÃO',
                value:
                    'R\$ ${(data.payments.totalReceivedCents / 100).toStringAsFixed(2)}',
                icon: Icons.savings,
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
              AdminMetricCard(
                label: 'PRODUTOS ATIVOS',
                value: '${data.products.ativos}',
                suffixText: 'ativos',
                icon: Icons.inventory_2,
              ),
              AdminMetricCard(
                label: 'PAGAMENTOS',
                value: '${data.payments.pending}',
                suffixText: 'pendentes',
                icon: Icons.payment,
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildRecentAttendance() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MESA DE CONTROLE',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                    const SizedBox(height: 4),
                    Text('Últimas Confirmações',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontSize: 24)),
                  ],
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/admin/presenca'),
                  child: const Text('Ver Todos'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FutureBuilder<List<dynamic>>(
              future: _attendanceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AdminLoadingState();
                }
                if (snapshot.hasError) {
                  return AdminErrorState(
                      message: 'Falha ao carregar presença.',
                      onRetry: _loadData);
                }

                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const AdminEmptyState(
                      message: 'Nenhum RSVP registrado.');
                }

                return LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth < 650) {
                    return Column(
                        children: items.map((item) {
                      final rsvp = item as Map<String, dynamic>;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(rsvp['nome'] as String? ?? ''),
                        subtitle: Text(
                            '${rsvp['vaiComparecer'] == true ? 'Confirmado' : 'Recusado'} • ${rsvp['qtdAdultos']} adultos / ${rsvp['qtdCriancas']} crianças'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => Navigator.pushNamed(
                            context, '/admin/presenca/${rsvp['id']}'),
                      );
                    }).toList());
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Convidado')),
                        DataColumn(label: Text('Adultos / Crianças')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: items.map((item) {
                        final rsvp = item as Map<String, dynamic>;
                        final status = rsvp['vaiComparecer'] == true;

                        return DataRow(
                          cells: [
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(rsvp['nome'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  Text(rsvp['email'] ?? '',
                                      style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            DataCell(Text(
                                '${rsvp['qtdAdultos']} / ${rsvp['qtdCriancas']}')),
                            DataCell(
                              Chip(
                                label: Text(status ? 'Confirmado' : 'Recusado',
                                    style: theme.textTheme.labelSmall),
                                backgroundColor: status
                                    ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.4)
                                    : theme.colorScheme.errorContainer,
                                side: BorderSide.none,
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () => Navigator.pushNamed(
                                    context, '/admin/presenca/${rsvp['id']}'),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPayments() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('FINANCEIRO',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 4),
            Text('Pagamentos Recentes',
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24)),
            const SizedBox(height: 16),
            FutureBuilder<List<dynamic>>(
              future: _paymentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AdminLoadingState();
                }
                if (snapshot.hasError) {
                  return AdminErrorState(message: 'Falha.', onRetry: _loadData);
                }

                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const AdminEmptyState(
                      message: 'Nenhum pagamento registrado.');
                }

                return Column(
                  children: items.map((item) {
                    final payment = item as Map<String, dynamic>;
                    final cents = payment['amountCents'] as int? ?? 0;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        child: Icon(Icons.attach_money,
                            color: theme.colorScheme.secondary),
                      ),
                      title: Text(payment['senderName'] ?? 'Desconhecido',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(payment['status'] ?? 'Unknown'),
                      trailing: Text('R\$ ${(cents / 100).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SISTEMA',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 4),
            Text('Atividades',
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24)),
            const SizedBox(height: 16),
            FutureBuilder<List<DashboardActivity>>(
              future: _activityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AdminLoadingState();
                }
                if (snapshot.hasError) {
                  return AdminErrorState(message: 'Falha.', onRetry: _loadData);
                }

                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const AdminEmptyState(
                      message: 'Nenhuma atividade recente.');
                }

                return Column(
                  children: items.take(5).map((activity) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle,
                              size: 8,
                              color: theme.colorScheme.primaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${activity.entityType} • ${activity.action}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13)),
                                Text(activity.description,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
