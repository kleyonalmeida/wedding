import 'package:flutter/material.dart';
import 'admin_session_controller.dart';
import '../theme/admin_theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AdminShell({super.key, required this.child, required this.currentPath});

  static const _navItems = [
    (path: '/admin/dashboard', label: 'Dashboard', icon: Icons.grid_view),
    (path: '/admin/produtos', label: 'Produtos', icon: Icons.inventory_2),
    (path: '/admin/pagamentos', label: 'Pagamentos', icon: Icons.payments),
    (path: '/admin/presenca', label: 'Presença', icon: Icons.how_to_reg),
    (path: '/admin/logs', label: 'Logs', icon: Icons.history),
    (
      path: '/admin/configuracoes',
      label: 'Configurações',
      icon: Icons.settings
    ),
    (path: '/admin/seguranca', label: 'Segurança', icon: Icons.shield),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.theme,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 960;
            return Row(
              children: [
                if (isDesktop) _buildSidebar(context),
                Expanded(
                  child: Column(
                    children: [
                      Builder(
                        builder: (headerContext) =>
                            _buildHeader(headerContext, isDesktop),
                      ),
                      Expanded(
                        child: Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        drawer: MediaQuery.of(context).size.width <= 960
            ? Drawer(
                child: Builder(
                    builder: (drawerContext) =>
                        _buildSidebar(drawerContext, isDrawer: true)))
            : null,
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    final theme = Theme.of(context);
    final sidebar = Container(
      width: 288,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite,
                        color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Kleyon & Liandra',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontSize: 18))),
                  ],
                ),
                Text('CERIMONIAL PRIVÉ',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('MENU PRINCIPAL',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
          ),
          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final item in _navItems)
                  _buildNavItem(
                      context, item.path, item.label, item.icon, isDrawer),
              ],
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    final controller = AdminSessionProvider.of(context);
                    await controller.api.post('/api/admin/auth/logout', {});
                    controller.requireLogin();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Flexible(
                            child: Text('ENCERRAR SESSÃO',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return sidebar;
  }

  Widget _buildNavItem(BuildContext context, String path, String label,
      IconData icon, bool isDrawer) {
    final theme = Theme.of(context);
    final isActive = currentPath.startsWith(path);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          if (isDrawer) Navigator.pop(context); // Close drawer
          if (currentPath != path) Navigator.pushNamed(context, path);
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isActive
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isActive ? FontWeight.w500 : FontWeight.w400,
                      ))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);

    // Breadcrumb logic
    String activeLabel = 'Dashboard';
    for (final item in _navItems) {
      if (currentPath.startsWith(item.path)) {
        activeLabel = item.label;
        break;
      }
    }

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isDesktop)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              if (isDesktop) ...[
                Text('PAINEL ADMINISTRATIVO',
                    style: theme.textTheme.labelSmall),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child:
                      Text('/', style: TextStyle(fontWeight: FontWeight.w300)),
                ),
              ],
              Text(activeLabel,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            children: [
              if (isDesktop)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Liandra & Kleyon',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    Text('CASAL • GESTORES', style: theme.textTheme.labelSmall),
                  ],
                ),
              if (isDesktop) const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                radius: 16,
                child: const Icon(Icons.person, size: 18),
              ),
            ],
          )
        ],
      ),
    );
  }
}
