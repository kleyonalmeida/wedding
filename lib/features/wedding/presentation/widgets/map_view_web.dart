import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

void registerGoogleMapView(String viewType, String mapSrc) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => web.HTMLIFrameElement()
      ..src = mapSrc
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true,
  );
}
