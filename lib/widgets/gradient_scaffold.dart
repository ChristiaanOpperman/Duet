import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';

/// The page chrome every screen sits in: a violet night gradient with two
/// slowly drifting colour blooms behind the content. The blooms are what stop
/// the app reading as a flat form — they are deliberately subtle and slow.
class GradientScaffold extends StatefulWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.bottomBar,
    this.padding = const EdgeInsets.symmetric(horizontal: Insets.gutter),
  });

  final Widget child;

  /// Pinned to the bottom above the safe area — the page's primary action.
  final Widget? bottomBar;

  final EdgeInsets padding;

  @override
  State<GradientScaffold> createState() => _GradientScaffoldState();
}

class _GradientScaffoldState extends State<GradientScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.backdrop),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _drift,
                builder: (context, _) => CustomPaint(
                  painter: _BloomPainter(_drift.value),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Insets.maxContentWidth,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: widget.padding,
                            child: widget.child,
                          ),
                        ),
                        if (widget.bottomBar != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Insets.gutter,
                              Insets.m,
                              Insets.gutter,
                              Insets.m,
                            ),
                            child: widget.bottomBar,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BloomPainter extends CustomPainter {
  const _BloomPainter(this.t);

  /// 0..1, looping.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    _bloom(
      canvas,
      size,
      centre: Offset(
        size.width * (0.18 + 0.12 * math.cos(angle)),
        size.height * (0.16 + 0.06 * math.sin(angle)),
      ),
      radius: size.shortestSide * 0.85,
      colour: AppColors.violet,
      opacity: 0.30,
    );
    _bloom(
      canvas,
      size,
      centre: Offset(
        size.width * (0.86 + 0.10 * math.cos(angle + math.pi * 0.8)),
        size.height * (0.74 + 0.08 * math.sin(angle + math.pi * 0.8)),
      ),
      radius: size.shortestSide * 0.95,
      colour: AppColors.magenta,
      opacity: 0.22,
    );
  }

  void _bloom(
    Canvas canvas,
    Size size, {
    required Offset centre,
    required double radius,
    required Color colour,
    required double opacity,
  }) {
    final rect = Rect.fromCircle(center: centre, radius: radius);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colour.withValues(alpha: opacity),
            colour.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BloomPainter oldDelegate) => oldDelegate.t != t;
}
