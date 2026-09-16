import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Press-and-hold to continue. Used on the handoff gates so a stray tap from
/// the wrong person can't reveal someone's private questions.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.label,
    required this.onComplete,
    this.holdLabel = 'Keep holding…',
    this.gradient,
    this.duration = const Duration(milliseconds: 700),
  });

  final String label;
  final String holdLabel;
  final VoidCallback onComplete;
  final Gradient? gradient;
  final Duration duration;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _start() => _hold.forward();

  void _cancel() {
    if (!_hold.isCompleted) _hold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ??
        const LinearGradient(
          colors: [AppColors.magenta, AppColors.violet],
        );

    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _cancel(),
      onTapCancel: _cancel,
      child: AnimatedBuilder(
        animation: _hold,
        builder: (context, _) {
          final progress = _hold.value;
          return Container(
            width: double.infinity,
            height: 62,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(Radii.button),
              border: Border.all(color: AppColors.hairlineStrong),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.18 + progress * 0.3),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: gradient),
                    child: const SizedBox.expand(),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        progress > 0
                            ? Icons.lock_open_rounded
                            : Icons.touch_app_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: Insets.s),
                      Text(
                        progress > 0.05 ? widget.holdLabel : widget.label,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Colors.white, fontSize: 17),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
