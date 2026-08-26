import 'package:flutter/material.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import '../../../../core/constants/wedding_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

class WeddingHeader extends StatelessWidget {
  final bool isScrolled;
  final VoidCallback onHomeTap;
  final VoidCallback onCasalTap;
  final VoidCallback onPadrinhosTap;
  final VoidCallback onRecepcaoTap;
  final VoidCallback onListaTap;
  final VoidCallback onRsvpTap;
  final VoidCallback? onMenuTap; // Callback for hamburger menu

  const WeddingHeader({
    super.key,
    required this.isScrolled,
    required this.onHomeTap,
    required this.onCasalTap,
    required this.onPadrinhosTap,
    required this.onRecepcaoTap,
    required this.onListaTap,
    required this.onRsvpTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: isScrolled ? 80 : 100, // Reduced height when scrolled
      decoration: BoxDecoration(
        color: isScrolled ? Theme.of(context).colorScheme.surface.withAlpha(240) : Colors.transparent,
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
                  color: isScrolled ? Theme.of(context).colorScheme.onSurface : AppColors.white,
                ),
              ),
              if (MediaQuery.of(context).size.width >= WeddingConstants.expandedBreakpoint)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem(context, 'HOME', onHomeTap, isScrolled),
                    const SizedBox(width: 32),
                    _buildMenuItem(context, 'O CASAL', onCasalTap, isScrolled),
                    const SizedBox(width: 32),
                    _buildMenuItem(context, 'PADRINHOS', onPadrinhosTap, isScrolled),
                    const SizedBox(width: 32),
                    _buildMenuItem(context, 'RECEPÇÃO', onRecepcaoTap, isScrolled),
                    const SizedBox(width: 32),
                    _buildMenuItem(context, 'LISTA DE PRESENTES', onListaTap, isScrolled),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (MediaQuery.of(context).size.width < WeddingConstants.expandedBreakpoint)
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: isScrolled ? Theme.of(context).colorScheme.onSurface : AppColors.white,
                          ),
                          onPressed: onMenuTap,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: onRsvpTap,
                      child: const Text('PRESENÇA'),
                    ),
                  const SizedBox(width: 16),
                  ThemeSwitcher(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            key: ValueKey(isDark),
                            color: isScrolled ? Theme.of(context).colorScheme.onSurface : AppColors.white,
                          ),
                        ),
                        onPressed: () {
                          ThemeSwitcher.of(context).changeTheme(
                            theme: isDark ? AppTheme.lightTheme : AppTheme.darkTheme,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, VoidCallback onTap, bool isScrolled) {
    return InkWell(
      onTap: onTap,
      child: Text(
        title,
        style: AppTextStyles.sans.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
          color: isScrolled ? Theme.of(context).colorScheme.onSurface : AppColors.white,
        ),
      ),
    );
  }
}
