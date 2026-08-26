import 'package:flutter/material.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

class WeddingSideMenu extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onCasalTap;
  final VoidCallback onRecepcaoTap;
  final VoidCallback onListaTap;
  final VoidCallback onRsvpTap;

  const WeddingSideMenu({
    super.key,
    required this.onHomeTap,
    required this.onCasalTap,
    required this.onRecepcaoTap,
    required this.onListaTap,
    required this.onRsvpTap,
  });

  void _handleNavigation(BuildContext context, VoidCallback callback) {
    Navigator.of(context).pop(); // Close drawer
    // Small delay to allow the drawer animation to start before scrolling
    Future.delayed(const Duration(milliseconds: 300), callback);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.65,
      child: Drawer(
        backgroundColor: const Color(0xFF957E6E),
        child: SafeArea(
          child: Transform.scale(
            scale: 0.85,
            child: Column(
          children: [
            const SizedBox(height: 32),
            Text(
              'K&L',
              style: AppTextStyles.serif.copyWith(
                fontSize: 32,
                letterSpacing: 6.0,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 50,
              height: 2,
              color: Colors.white70,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildMenuItem(context, 'HOME', () => _handleNavigation(context, onHomeTap)),
                  _buildMenuItem(context, 'O CASAL', () => _handleNavigation(context, onCasalTap)),
                  _buildMenuItem(context, 'RECEPÇÃO', () => _handleNavigation(context, onRecepcaoTap)),
                  _buildMenuItem(context, 'LISTA DE PRESENTES', () => _handleNavigation(context, onListaTap)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _handleNavigation(context, onRsvpTap),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF957E6E),
                    ),
                    child: const Text('PRESENÇA'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ThemeSwitcher(
                builder: (context) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isDark ? 'Modo Claro' : 'Modo Escuro',
                        style: AppTextStyles.sans.copyWith(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            key: ValueKey(isDark),
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          ThemeSwitcher.of(context).changeTheme(
                            theme: isDark ? AppTheme.lightTheme : AppTheme.darkTheme,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildMenuItem(BuildContext context, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.sans.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
