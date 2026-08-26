import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void registerGoogleMapView(String viewType, String mapSrc) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => html.IFrameElement()
      ..src = mapSrc
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true,
  );
}
