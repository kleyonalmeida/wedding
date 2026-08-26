import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class MapaCasamentoWidget extends StatefulWidget {
  final String mapSrc;
  final double height;

  const MapaCasamentoWidget({
    super.key,
    this.mapSrc = 'https://maps.google.com/maps?q=Casa%20da%20Mangueira%20Eventos&t=&z=15&ie=UTF8&iwloc=&output=embed',
    this.height = 400,
  });

  @override
  State<MapaCasamentoWidget> createState() => _MapaCasamentoWidgetState();
}

class _MapaCasamentoWidgetState extends State<MapaCasamentoWidget> {
  static const String _viewType = 'google-map-iframe';
  static bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    if (!_isRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => html.IFrameElement()
          ..src = widget.mapSrc
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true,
      );
      _isRegistered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: const HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
