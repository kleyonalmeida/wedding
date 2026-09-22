import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'map_view_fallback.dart' if (dart.library.html) 'map_view_web.dart';

class MapaCasamentoWidget extends StatefulWidget {
  final String mapSrc;
  final double height;

  const MapaCasamentoWidget({
    super.key,
    this.mapSrc =
        'https://maps.google.com/maps?q=Casa%20da%20Mangueira%20Eventos&t=&z=15&ie=UTF8&iwloc=&output=embed',
    this.height = 400,
  });

  @override
  State<MapaCasamentoWidget> createState() => _MapaCasamentoWidgetState();
}

class _MapaCasamentoWidgetState extends State<MapaCasamentoWidget> {
  static const String _viewType = 'google-map-iframe';
  static bool _isRegistered = false;
  Timer? _loadTimer;
  bool _showInteractiveMap = false;

  @override
  void initState() {
    super.initState();
    if (!_isRegistered && kIsWeb) {
      registerGoogleMapView(_viewType, widget.mapSrc);
      _isRegistered = true;
    }
    _scheduleMapLoad();
  }

  void _scheduleMapLoad() {
    _loadTimer?.cancel();
    _loadTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (Scrollable.recommendDeferredLoadingForContext(context)) {
        _scheduleMapLoad();
        return;
      }
      setState(() => _showInteractiveMap = true);
    });
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _showInteractiveMap && kIsWeb
              ? const HtmlElementView(
                  key: ValueKey('interactive-map'),
                  viewType: _viewType,
                )
              : ColoredBox(
                  key: const ValueKey('map-placeholder'),
                  color: Theme.of(context).colorScheme.surface,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
        ),
      ),
    );
  }
}
