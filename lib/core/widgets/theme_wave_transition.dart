import 'dart:math' as math;

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';

/// Revela o novo tema com uma frente circular de velocidade radial constante.
///
/// Esta implementação corrige dois detalhes do ThemeSwitchingArea original:
/// a captura física é forçada a preencher o viewport lógico e a origem global
/// do botão é convertida para o sistema de coordenadas local da área animada.
class ThemeWaveTransition extends StatefulWidget {
  final Widget child;

  const ThemeWaveTransition({super.key, required this.child});

  @override
  State<ThemeWaveTransition> createState() => _ThemeWaveTransitionState();
}

class _ThemeWaveTransitionState extends State<ThemeWaveTransition> {
  final GlobalKey _areaKey = GlobalKey();

  Offset _localOrigin(Offset globalOrigin) {
    final renderBox = _areaKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.globalToLocal(globalOrigin) ?? globalOrigin;
  }

  @override
  Widget build(BuildContext context) {
    final model = ThemeModelInheritedNotifier.of(context);
    final isTransitioning = model.oldTheme != null &&
        model.oldTheme != model.theme &&
        model.image != null &&
        model.controller.isAnimating;

    Widget themedPage(ThemeData theme) {
      return Theme(
        data: theme,
        child: ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: widget.child,
        ),
      );
    }

    if (!isTransitioning) {
      return SizedBox.expand(
        key: _areaKey,
        child: Material(
          color: model.theme.scaffoldBackgroundColor,
          child: themedPage(model.theme),
        ),
      );
    }

    final origin = _localOrigin(model.switcherOffset);
    final screenshot = RawImage(
      image: model.image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
    );
    final base = model.isReversed ? themedPage(model.theme) : screenshot;
    final revealed = model.isReversed ? screenshot : themedPage(model.theme);

    return SizedBox.expand(
      key: _areaKey,
      child: Material(
        color: model.theme.scaffoldBackgroundColor,
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: base),
            Positioned.fill(
              child: ClipPath(
                clipBehavior: Clip.antiAlias,
                clipper: _LinearWaveClipper(
                  animation: model.controller,
                  origin: origin,
                  reversed: model.isReversed,
                ),
                child: revealed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinearWaveClipper extends CustomClipper<Path> {
  final Animation<double> animation;
  final Offset origin;
  final bool reversed;

  _LinearWaveClipper({
    required this.animation,
    required this.origin,
    required this.reversed,
  }) : super(reclip: animation);

  @override
  Path getClip(Size size) {
    final horizontal =
        math.max(origin.dx.abs(), (size.width - origin.dx).abs());
    final vertical = math.max(origin.dy.abs(), (size.height - origin.dy).abs());
    final maximumRadius = math.sqrt(
      horizontal * horizontal + vertical * vertical,
    );
    final progress = reversed ? 1.0 - animation.value : animation.value;

    // Dois pixels extras impedem que o antialias revele uma fresta no canto.
    final radius = (maximumRadius + 2.0) * progress;
    return Path()..addOval(Rect.fromCircle(center: origin, radius: radius));
  }

  @override
  bool shouldReclip(covariant _LinearWaveClipper oldClipper) {
    return oldClipper.origin != origin || oldClipper.reversed != reversed;
  }
}
