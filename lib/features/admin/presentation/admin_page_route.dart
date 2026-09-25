import 'package:flutter/material.dart';

/// Cada URL administrativa possui um único layout ativo. A rota anterior
/// permanece no histórico, mas sua árvore é desmontada enquanto está coberta.
class AdminPageRoute extends PageRouteBuilder<void> {
  AdminPageRoute(
      {required RouteSettings settings, required WidgetBuilder builder})
      : super(
          settings: settings,
          opaque: true,
          maintainState: false,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, _, __) => builder(context),
        );
}
