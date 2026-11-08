import 'package:flutter/material.dart';
import 'theme.dart';

Duration motionDuration(BuildContext context, [int milliseconds = 450]) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

/// A finite entrance, with no timers or continuous animation when offscreen.
class SoftEntrance extends StatelessWidget {
  final Widget child;
  final int order;
  const SoftEntrance({super.key, required this.child, this.order = 0});
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + order.clamp(0, 5) * 40),
      curve: Interval(
        (order.clamp(0, 5) * 40) / (420 + order.clamp(0, 5) * 40),
        1,
        curve: Curves.easeOutCubic,
      ),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class WellnessSurface extends StatelessWidget {
  final Widget child;
  const WellnessSurface({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: purple.withValues(alpha: .22),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4423C6),
                    Color(0xFF7756F7),
                    Color(0xFF977CFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          PositionedDirectional(top: -65, end: -35, child: _orb(190, .09)),
          PositionedDirectional(bottom: -90, start: -40, child: _orb(220, .06)),
          PositionedDirectional(
            top: 24,
            end: 28,
            child: Transform.rotate(
              angle: -.55,
              child: Container(
                width: 68,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(26), child: child),
        ],
      ),
    ),
  );
  Widget _orb(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: opacity),
        width: 24,
      ),
    ),
  );
}
