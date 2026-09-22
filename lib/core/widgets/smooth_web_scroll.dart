import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Um wrapper nativo para suavizar a rolagem do mouse no Flutter Web,
/// substituindo saltos bruscos por animações fluidas.
class SmoothWebScroll extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  /// Quantidade de pixels a rolar por cada "tick" (catracada) do mouse.
  final double scrollAmount;

  /// Duração da inércia/deslizamento da rolagem.
  final Duration animationDuration;

  const SmoothWebScroll({
    super.key,
    required this.controller,
    required this.child,
    this.scrollAmount = 80.0, // Quantidade de pixels por pulo
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<SmoothWebScroll> createState() => _SmoothWebScrollState();
}

class _SmoothWebScrollState extends State<SmoothWebScroll>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _velocity = 0.0;
  double _restingOffset = 0.0;
  Duration? _lastTick;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _restingOffset = widget.controller.initialScrollOffset;
  }

  @override
  void didUpdateWidget(covariant SmoothWebScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _ticker.stop();
      _velocity = 0;
      _lastTick = null;
      _restingOffset = widget.controller.hasClients
          ? widget.controller.offset
          : widget.controller.initialScrollOffset;
    }
  }

  double get _timeConstantSeconds {
    final settleSeconds = math.max(
      widget.animationDuration.inMicroseconds / Duration.microsecondsPerSecond,
      0.001,
    );
    return settleSeconds / 3.0;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && widget.controller.hasClients) {
      if (event.scrollDelta.dy == 0) return;
      final direction = event.scrollDelta.dy > 0 ? 1 : -1;
      final current = widget.controller.offset;
      final maxScroll = widget.controller.position.maxScrollExtent;
      final timeConstant = _timeConstantSeconds;

      // Cada catracada acrescenta velocidade à inércia existente. Como a área
      // da curva exponencial é velocidade * constante de tempo, este impulso
      // ainda percorre exatamente scrollAmount quando não encontra um limite.
      _velocity += direction * widget.scrollAmount / timeConstant;

      _restingOffset =
          (current + _velocity * timeConstant).clamp(0.0, maxScroll).toDouble();
      _velocity = (_restingOffset - current) / timeConstant;

      if (!_ticker.isActive) {
        _lastTick = null;
        _ticker.start();
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (!widget.controller.hasClients) return;

    final current = widget.controller.offset;
    final maxScroll = widget.controller.position.maxScrollExtent;
    final timeConstant = _timeConstantSeconds;

    if (_velocity.abs() < 1.0) {
      _restingOffset = _restingOffset.clamp(0.0, maxScroll).toDouble();
      widget.controller.jumpTo(_restingOffset);
      _velocity = 0;
      _ticker.stop();
      _lastTick = null;
      return;
    }

    final previousTick = _lastTick;
    _lastTick = elapsed;
    if (previousTick == null) return;

    final deltaSeconds = (elapsed - previousTick).inMicroseconds /
        Duration.microsecondsPerSecond;
    final decay = math.exp(-deltaSeconds / timeConstant);
    final displacement = _velocity * timeConstant * (1.0 - decay);
    final nextOffset =
        (current + displacement).clamp(0.0, maxScroll).toDouble();
    widget.controller.jumpTo(nextOffset);
    _velocity *= decay;

    if ((nextOffset <= 0 && _velocity < 0) ||
        (nextOffset >= maxScroll && _velocity > 0)) {
      widget.controller.jumpTo(_restingOffset);
      _velocity = 0;
      _ticker.stop();
      _lastTick = null;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _handlePointerSignal,
      child: widget.child,
    );
  }
}
