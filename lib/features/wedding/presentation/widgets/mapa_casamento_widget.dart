import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'map_view_fallback.dart'
    if (dart.library.js_interop) 'map_view_web.dart';

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
  bool _showInteractiveMap = false;

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
        child: _showInteractiveMap && kIsWeb
            ? Column(
                children: [
                  Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.map_outlined),
                      title: const Text('Mapa interativo ativo'),
                      trailing: TextButton.icon(
                        onPressed: () =>
                            setState(() => _showInteractiveMap = false),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('FECHAR'),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: HtmlElementView(viewType: _viewType),
                  ),
                ],
              )
            : ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Casa da Mangueira Eventos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: kIsWeb
                            ? () => setState(() => _showInteractiveMap = true)
                            : null,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('CARREGAR MAPA INTERATIVO'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
