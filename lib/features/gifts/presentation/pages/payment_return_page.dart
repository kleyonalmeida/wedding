import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';

class PaymentReturnPage extends StatefulWidget {
  final String orderId;

  const PaymentReturnPage({super.key, required this.orderId});

  @override
  State<PaymentReturnPage> createState() => _PaymentReturnPageState();
}

class _PaymentReturnPageState extends State<PaymentReturnPage> {
  final ApiClient api = ApiClient();
  String status = 'Carregando pedido...';

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final token = Uri.splitQueryString(Uri.base.fragment)['token'];
    if (widget.orderId.isEmpty || token == null) {
      setState(() => status =
          'Link de retorno incompleto. Consulte os noivos sobre o pedido.');
      return;
    }
    try {
      final order = await api.get(
          '/api/gift-orders/${widget.orderId}?token=${Uri.encodeQueryComponent(token)}');
      if (!mounted) return;
      final current = order['status'] as String? ?? 'Pending';
      setState(() => status = switch (current) {
            'Confirmed' ||
            'Received' =>
              'Pagamento confirmado. Obrigado pelo presente!',
            'Refunded' ||
            'Cancelled' ||
            'Overdue' =>
              'O pagamento não foi concluído.',
            _ =>
              'Pedido recebido. A confirmação do pagamento ainda está pendente.',
          });
    } catch (_) {
      if (mounted) {
        setState(() => status =
            'Não foi possível consultar o pedido agora. Tente novamente mais tarde.');
      }
    }
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Retorno do Pagamento', style: AppTextStyles.serif),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.card_giftcard,
                  size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Situação do presente',
                style: AppTextStyles.serif
                    .copyWith(fontSize: 28, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Voltar ao Início',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
