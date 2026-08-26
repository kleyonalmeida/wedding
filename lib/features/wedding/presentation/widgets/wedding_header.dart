import 'package:flutter/material.dart';
import '../../../../core/constants/wedding_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class WeddingHeader extends StatelessWidget {
  final bool isScrolled;
  final VoidCallback onHomeTap;
  final VoidCallback onCasalTap;
  final VoidCallback onPadrinhosTap;
  final VoidCallback onRecepcaoTap;
  final VoidCallback onListaTap;
  final VoidCallback onRsvpTap;

  const WeddingHeader({
    super.key,
    required this.isScrolled,
    required this.onHomeTap,
    required this.onCasalTap,
    required this.onPadrinhosTap,
    required this.onRecepcaoTap,
    required this.onListaTap,
    required this.onRsvpTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: isScrolled ? 80 : 100, // Reduced height when scrolled
      decoration: BoxDecoration(
        color: isScrolled ? AppColors.white.withAlpha(240) : Colors.transparent,
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ]
            : [],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'K&L',
                style: AppTextStyles.serif.copyWith(
                  fontSize: 24,
                  letterSpacing: 4.0,
                  color: isScrolled ? AppColors.dark : AppColors.white,
                ),
              ),
              if (MediaQuery.of(context).size.width >= WeddingConstants.expandedBreakpoint)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem('HOME', onHomeTap, isScrolled),
                    const SizedBox(width: 32),
                    _buildMenuItem('O CASAL', onCasalTap, isScrolled),
                    const SizedBox(width: 32),
                    _buildMenuItem('PADRINHOS', onPadrinhosTap, isScrolled),
                    const SizedBox(width: 32),
                    _buildMenuItem('RECEPÇÃO', onRecepcaoTap, isScrolled),
                    const SizedBox(width: 32),
                    _buildMenuItem('LISTA DE PRESENTES', onListaTap, isScrolled),
                  ],
                ),
              ElevatedButton(
                onPressed: onRsvpTap,
                child: const Text('PRESENÇA'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, VoidCallback onTap, bool isScrolled) {
    return InkWell(
      onTap: onTap,
      child: Text(
        title,
        style: AppTextStyles.sans.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
          color: isScrolled ? AppColors.dark : AppColors.white,
        ),
      ),
    );
  }
}
