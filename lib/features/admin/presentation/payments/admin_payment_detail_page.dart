import 'package:flutter/material.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/models/payment.dart';
import '../shell/admin_session_controller.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_widgets.dart';

class AdminPaymentDetailPage extends StatefulWidget {
  final String paymentId;

  const AdminPaymentDetailPage({super.key, required this.paymentId});

  @override
  State<AdminPaymentDetailPage> createState() => _AdminPaymentDetailPageState();
}

class _AdminPaymentDetailPageState extends State<AdminPaymentDetailPage> {
  late PaymentRepository _repository;

  PaymentDetail? _payment;
  List<PaymentEvent>? _events;
  bool _isLoading = false;
  String? _error;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _repository = PaymentRepository(AdminSessionController.instance.api);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final payment = await _repository.get(widget.paymentId);
      final events = await _repository.getEvents(widget.paymentId);

      if (mounted) {
        setState(() {
          _payment = payment;
          _events = events;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar os detalhes do pagamento.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncPayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sincronizar Pagamento?'),
        content: const Text(
            'Isso fará uma consulta direta na Asaas para verificar o status mais recente, contornando o webhook. Deseja prosseguir?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sincronizar')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSyncing = true);
      try {
        final newStatus = await _repository.syncPayment(widget.paymentId);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Sincronizado com sucesso! Novo status: $newStatus')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Falha ao sincronizar pagamento. Consulte os logs.')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _payment == null) {
      return const AdminLoadingState(message: 'Carregando pagamento...');
    }

    if (_error != null && _payment == null) {
      return AdminErrorState(message: _error!, onRetry: _loadData);
    }

    if (_payment == null) {
      return const AdminEmptyState(message: 'Pagamento não encontrado.');
    }

    final theme = Theme.of(context);
    final statusColor =
        _payment!.status == 'Confirmed' || _payment!.status == 'Received'
            ? Colors.green
            : (_payment!.status == 'Pending'
                ? Colors.orange
                : theme.colorScheme.error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: AdminPageHeader(
            title: 'Detalhes do Pagamento',
            subtitle:
                'Referência: ${_payment!.gatewayPaymentId ?? _payment!.id}',
            trailing: FilledButton.icon(
              onPressed: _isSyncing ? null : _syncPayment,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              label: const Text('Forçar Sincronização'),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 800;
              final gap = compact ? 0.0 : 24.0;
              return Wrap(
                spacing: gap,
                runSpacing: 16,
                children: [
                  // Esquerda: Detalhes do Pedido e Itens
                  SizedBox(
                    width: compact
                        ? constraints.maxWidth
                        : (constraints.maxWidth - gap) * 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('INFORMAÇÕES DO PAGAMENTO',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.outline)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                          context,
                                          'Status',
                                          Chip(
                                            label: Text(_payment!.status,
                                                style:
                                                    theme.textTheme.labelSmall),
                                            backgroundColor: statusColor
                                                .withValues(alpha: 0.2),
                                            side: BorderSide.none,
                                          )),
                                    ),
                                    Expanded(
                                        child: _buildInfoItem(
                                            context,
                                            'Método',
                                            Text(_payment!.billingType,
                                                style: theme
                                                    .textTheme.bodyMedium))),
                                    Expanded(
                                        child: _buildInfoItem(
                                            context,
                                            'Data de Criação',
                                            Text(
                                                '${_payment!.createdAtUtc.day}/${_payment!.createdAtUtc.month}/${_payment!.createdAtUtc.year}',
                                                style: theme
                                                    .textTheme.bodyMedium))),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                        child: _buildInfoItem(
                                            context,
                                            'Valor Cobrado',
                                            Text(
                                                'R\$ ${(_payment!.amountCents / 100).toStringAsFixed(2)}',
                                                style: theme
                                                    .textTheme.titleMedium))),
                                    Expanded(
                                        child: _buildInfoItem(
                                            context,
                                            'Valor Líquido',
                                            Text(
                                                'R\$ ${(_payment!.netCents / 100).toStringAsFixed(2)}',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                        color: Colors.green)))),
                                    Expanded(
                                        child: _buildInfoItem(
                                            context,
                                            'Taxa',
                                            Text(
                                                'R\$ ${((_payment!.amountCents - _payment!.netCents) / 100).toStringAsFixed(2)}',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .error)))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_payment!.order != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MENSAGEM DO REMETENTE',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color:
                                                  theme.colorScheme.outline)),
                                  const SizedBox(height: 16),
                                  Text(_payment!.order!.senderName,
                                      style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                        _payment!.order!.message?.isNotEmpty ==
                                                true
                                            ? _payment!.order!.message!
                                            : 'Sem mensagem',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontStyle: FontStyle.italic)),
                                  ),
                                  const SizedBox(height: 24),
                                  Text('ITENS PRESENTADOS',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color:
                                                  theme.colorScheme.outline)),
                                  const SizedBox(height: 8),
                                  ..._payment!.order!.items
                                      .map((item) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: CircleAvatar(
                                              backgroundColor: theme
                                                  .colorScheme.primaryContainer,
                                              child: Text('${item.quantity}x',
                                                  style: TextStyle(
                                                      color: theme.colorScheme
                                                          .onPrimaryContainer,
                                                      fontSize: 12)),
                                            ),
                                            title: Text(item.name),
                                            trailing: Text(
                                                'R\$ ${(item.priceCents / 100).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          )),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Direita: Timeline de Eventos
                  SizedBox(
                    width: compact
                        ? constraints.maxWidth
                        : (constraints.maxWidth - gap) * 0.4,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('HISTÓRICO DE EVENTOS (WEBHOOKS)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.outline)),
                            const SizedBox(height: 24),
                            if (_events == null || _events!.isEmpty)
                              const Text('Nenhum evento registrado.')
                            else
                              ..._events!
                                  .map((e) => _buildEventItem(context, e)),
                          ],
                        ),
                      ),
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

  Widget _buildInfoItem(BuildContext context, String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        content,
      ],
    );
  }

  Widget _buildEventItem(BuildContext context, PaymentEvent event) {
    final theme = Theme.of(context);
    final isError = event.status == 'Failed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                  isError
                      ? Icons.error
                      : (event.status == 'Processed'
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked),
                  size: 20,
                  color: isError
                      ? theme.colorScheme.error
                      : (event.status == 'Processed'
                          ? Colors.green
                          : theme.colorScheme.outline)),
              Container(
                  width: 1,
                  height: 32,
                  color: theme.colorScheme.outlineVariant),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(event.eventType,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                        '${event.receivedAtUtc.day}/${event.receivedAtUtc.month} ${event.receivedAtUtc.hour}:${event.receivedAtUtc.minute}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
                if (isError && event.errorCode != null)
                  Text('Erro: ${event.errorCode}',
                      style: TextStyle(
                          color: theme.colorScheme.error, fontSize: 12))
                else
                  Text(event.status, style: theme.textTheme.bodySmall),
              ],
            ),
          )
        ],
      ),
    );
  }
}
