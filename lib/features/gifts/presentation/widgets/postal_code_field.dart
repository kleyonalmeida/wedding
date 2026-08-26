import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PostalCodeField extends StatefulWidget {
  const PostalCodeField({super.key});

  @override
  State<PostalCodeField> createState() => _PostalCodeFieldState();
}

class _PostalCodeFieldState extends State<PostalCodeField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch() {
    // Apenas simula o clique do CEP por enquanto
    final cep = _controller.text.trim();
    if (cep.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buscando frete para $cep... (Simulado)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ONDE SERÁ A ENTREGA?',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.outlineVariant, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.outlineVariant, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Digite seu CEP',
                    hintStyle: TextStyle(color: AppColors.outlineVariant, fontSize: 14),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                onPressed: _handleSearch,
                splashRadius: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
