import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Hand-rolled confetti so the app keeps zero plugin dependencies.
///
/// Particles are seeded once when [play] flips to true, then integrated under
/// constant gravity for the life of the animation. Set [play] back to false to
/// clear them.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.play,
    this.count = 90,
    this.origin = const Alignment(0, -0.15),
    this.duration = const Duration(milliseconds: 2200),
  });

  final bool play;
  final int count;
  final Alignment origin;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const _palette = [
    AppColors.magenta,
    AppColors.violet,
    AppColors.cyan,
    AppColors.mint,
    AppColors.gold,
    Colors.white,
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  List<_Particle> _particles = const [];

  @override
  void initState() {
    super.initState();
    if (widget.play) _fire();
  }

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _fire();
    } else if (!widget.play && oldWidget.play) {
      _controller.stop();
      setState(() => _particles = const []);
    }
  }

  void _fire() {
    final random = math.Random();
    _particles = List.generate(widget.count, (_) {
      // Bias the spread upward so the burst arcs and falls back through frame.
      final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.35;
      final speed = 0.55 + random.nextDouble() * 0.85;
      return _Particle(
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        colour: _palette[random.nextInt(_palette.length)],
        size: 5 + random.nextDouble() * 7,
        spin: (random.nextDouble() - 0.5) * 9,
        phase: random.nextDouble() * math.pi * 2,
        drag: 0.55 + random.nextDouble() * 0.3,
      );
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            particles: _particles,
            t: _controller.value,
            origin: widget.origin,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.velocity,
    required this.colour,
    required this.size,
    required this.spin,
    required this.phase,
    required this.drag,
  });

  final Offset velocity;
  final Color colour;
  final double size;
  final double spin;
  final double phase;
  final double drag;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.particles,
    required this.t,
    required this.origin,
  });

  final List<_Particle> particles;
  final double t;
  final Alignment origin;

  @override
  void paint(Canvas canvas, Size size) {
    final start = origin.alongSize(size);
    final reach = size.shortestSide;
    const gravity = 1.9;
    // Fade out over the last third of the flight.
    final fade = t < 0.66 ? 1.0 : (1 - (t - 0.66) / 0.34).clamp(0.0, 1.0);

    for (final p in particles) {
      final travelled = t * p.drag;
      final dx = p.velocity.dx * travelled * reach;
      final dy = (p.velocity.dy * travelled + gravity * travelled * travelled) *
          reach;
      final centre = start + Offset(dx, dy);
      if (centre.dy > size.height + 40) continue;

      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(p.phase + p.spin * t * math.pi);
      // Squash on the vertical axis to read as a tumbling paper rectangle.
      final squash = math.cos(p.phase + t * p.spin * 4).abs().clamp(0.25, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 1.6 * squash,
          ),
          const Radius.circular(1.5),
        ),
        Paint()..color = p.colour.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
