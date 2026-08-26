import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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

class _SmoothWebScrollState extends State<SmoothWebScroll> {
  // Guarda o offset alvo atual para permitir acúmulo de rolagem se o usuário girar rápido
  double _targetOffset = 0.0;

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && widget.controller.hasClients) {
      // 2. A Lógica Matemática (O Segredo)
      // Capturamos a posição ATUAL do target (ou do controller se não estivermos animando)
      // e adicionamos o valor fixo (scrollAmount) dependendo da direção do scroll.
      final currentOffset = widget.controller.offset;
      
      // Se o mouse rolou para baixo (event.scrollDelta.dy > 0), somamos o scrollAmount.
      // Se rolou para cima (event.scrollDelta.dy < 0), subtraímos.
      final direction = event.scrollDelta.dy > 0 ? 1 : -1;
      
      // Se já estivermos no meio de uma animação, continuamos a partir do _targetOffset salvo.
      // Caso contrário, partimos da posição atual real da tela.
      final baseOffset = _targetOffset > 0 ? _targetOffset : currentOffset;
      
      double newTarget = baseOffset + (widget.scrollAmount * direction);

      // 3. Trava de Limites (Clamping)
      // Garante que o alvo não tente passar do tamanho máximo da tela nem fique menor que zero.
      final maxScroll = widget.controller.position.maxScrollExtent;
      _targetOffset = newTarget.clamp(0.0, maxScroll);

      // 4. A Animação (Inércia)
      // Executa a animação até o novo offset calculado usando uma curva de desaceleração.
      widget.controller.animateTo(
        _targetOffset,
        duration: widget.animationDuration,
        curve: Curves.easeOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. O Componente (Wrapper) retornando o Listener
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _handlePointerSignal,
      child: widget.child,
    );
  }
}
