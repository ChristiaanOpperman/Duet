import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';

/// Text painted with a gradient. Reserved for the wordmark and the winner's
/// name — used sparingly so it stays a moment rather than a texture.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = AppGradients.primary,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: textAlign,
        style: (style ?? Theme.of(context).textTheme.displayLarge)
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// The interlocking-rings mark — two halves of a pair, overlapping.
class DuetMark extends StatelessWidget {
  const DuetMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ring = size * 0.62;
    return SizedBox(
      width: size,
      height: ring,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          _Ring(diameter: ring, gradient: AppGradients.primary),
          Positioned(
            left: size - ring,
            child: _Ring(diameter: ring, gradient: AppGradients.cool),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.diameter, required this.gradient});

  final double diameter;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: diameter * 0.56,
          height: diameter * 0.56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0D0A1B),
          ),
        ),
      ),
    );
  }
}
