import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'map_view_fallback.dart' if (dart.library.html) 'map_view_web.dart';
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
    if (!_isRegistered && kIsWeb) {
      registerGoogleMapView(_viewType, widget.mapSrc);
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
