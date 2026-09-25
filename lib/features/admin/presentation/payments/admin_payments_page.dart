import 'package:wedding_app/app_navigation.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/models/payment.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_widgets.dart';
import '../widgets/admin_responsive_records.dart';

class AdminPaymentsPage extends StatefulWidget {
  final int initialPage;
  const AdminPaymentsPage({super.key, this.initialPage = 1});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  late PaymentRepository _repository;

  PaginatedPayments? _data;
  bool _isLoading = false;
  String? _error;

  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _repository = PaymentRepository(AdminSessionController.instance.api);
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar os pagamentos.';
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
            title: 'Gestão Financeira',
            subtitle: 'Pagamentos',
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
      return const AdminLoadingState(message: 'Carregando pagamentos...');
    }

    if (_error != null) {
      return AdminErrorState(message: _error!, onRetry: _loadData);
    }

    if (_data == null || _data!.items.isEmpty) {
      return const AdminEmptyState(message: 'Nenhum pagamento registrado.');
    }

    final theme = Theme.of(context);
    final totalPages = (_data!.total / _data!.pageSize).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AdminResponsiveRecords(
                cards: _data!.items
                    .map((payment) => Card(
                          child: ListTile(
                            title: Text(payment.senderName ?? 'Desconhecido'),
                            subtitle: Text(
                                '${payment.status} • ${payment.createdAtUtc.day}/${payment.createdAtUtc.month}/${payment.createdAtUtc.year}\n${payment.gatewayPaymentId ?? payment.id}'),
                            isThreeLine: true,
                            trailing: Text(
                                'R\$ ${(payment.amountCents / 100).toStringAsFixed(2)}'),
                            onTap: () => AppNavigation.go(
                                context, '/admin/pagamentos/${payment.id}'),
                          ),
                        ))
                    .toList(),
                table: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('ID / Referência')),
                    DataColumn(label: Text('Remetente')),
                    DataColumn(label: Text('Valor')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Data')),
                    DataColumn(label: Text('Detalhes')),
                  ],
                  rows: _data!.items.map((payment) {
                    final statusColor = payment.status == 'Confirmed' ||
                            payment.status == 'Received'
                        ? Colors.green
                        : (payment.status == 'Pending'
                            ? Colors.orange
                            : theme.colorScheme.error);

                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(payment.gatewayPaymentId ?? 'N/A',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              Text(payment.id.split('-').first,
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        DataCell(Text(payment.senderName ?? 'Desconhecido')),
                        DataCell(Text(
                            'R\$ ${(payment.amountCents / 100).toStringAsFixed(2)}')),
                        DataCell(Chip(
                          label: Text(payment.status,
                              style: theme.textTheme.labelSmall),
                          backgroundColor: statusColor.withValues(alpha: 0.2),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                        )),
                        DataCell(Text(
                            '${payment.createdAtUtc.day.toString().padLeft(2, '0')}/${payment.createdAtUtc.month.toString().padLeft(2, '0')}')),
                        DataCell(
                          IconButton(
                            tooltip: 'Ver Detalhes',
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () => AppNavigation.go(
                                context, '/admin/pagamentos/${payment.id}'),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            // Pagination
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _page > 1
                          ? () {
                              AppNavigation.go(context,
                                  '/admin/pagamentos?page=${_page - 1}');
                            }
                          : null,
                      child: const Text('Anterior'),
                    ),
                    const SizedBox(width: 16),
                    Text('Página $_page de $totalPages',
                        style: theme.textTheme.labelSmall),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _page < totalPages
                          ? () {
                              AppNavigation.go(context,
                                  '/admin/pagamentos?page=${_page + 1}');
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
