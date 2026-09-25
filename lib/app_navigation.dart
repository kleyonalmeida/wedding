import 'package:flutter/material.dart';

abstract interface class AppRouteHandler {
  void go(String path);
}

class AppNavigation {
  static void go(BuildContext context, String path) {
    (Router.of(context).routerDelegate as AppRouteHandler).go(path);
  }

  static void replace(BuildContext context, String path) {
    Router.neglect(context, () => go(context, path));
  }
}
