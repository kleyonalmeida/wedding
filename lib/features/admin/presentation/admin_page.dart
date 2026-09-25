import 'package:flutter/material.dart';
import 'admin_route.dart';
import 'auth/admin_first_access_page.dart';
import 'auth/admin_login_page.dart';
import 'auth/admin_mfa_page.dart';
import 'shell/admin_session_controller.dart';
import 'shell/admin_shell.dart';

class AdminPage extends StatelessWidget {
  final String path;
  const AdminPage({super.key, required this.path});

  @override
  Widget build(BuildContext context) => AdminSessionProvider(
        notifier: AdminSessionController.instance,
        child: AnimatedBuilder(
          animation: AdminSessionController.instance,
          builder: (context, _) {
            final phase = AdminSessionController.instance.phase;
            switch (phase) {
              case AdminSessionPhase.loading:
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              case AdminSessionPhase.login:
                return const Scaffold(body: AdminLoginPage());
              case AdminSessionPhase.verify:
              case AdminSessionPhase.enroll:
                return Scaffold(
                    body: AdminMfaPage(
                        isEnrollment: phase == AdminSessionPhase.enroll));
              case AdminSessionPhase.password:
                return const Scaffold(body: AdminFirstAccessPage());
              case AdminSessionPhase.forbidden:
                return const Scaffold(
                    body: Center(child: Text('Acesso negado')));
              case AdminSessionPhase.error:
                return const Scaffold(
                    body: Center(
                        child: Text(
                            'Não foi possível carregar a área administrativa')));
              case AdminSessionPhase.ready:
                return AdminShell(
                    currentPath: path, child: resolveAdminPage(path));
            }
          },
        ),
      );
}
