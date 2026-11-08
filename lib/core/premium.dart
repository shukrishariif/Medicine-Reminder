import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'motion.dart';
import 'theme.dart';

const careTeal = Color(0xFF087C70);

class OnboardingArtwork extends StatelessWidget {
  final int page;
  const OnboardingArtwork({super.key, required this.page});
  @override
  Widget build(BuildContext context) => Container(
    height: 258,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(36),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: Theme.of(context).brightness == Brightness.dark
            ? const [Color(0xFF332651), Color(0xFF1D3334)]
            : const [Color(0xFFF0E8FF), Color(0xFFF8F5FF), Color(0xFFE2F3EE)],
      ),
    ),
    child: Center(
      child: AnimatedSwitcher(
        duration: motionDuration(context, 400),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .94, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: Image.asset(
          [
            'assets/illustrations/care-today.png',
            'assets/illustrations/smart-reminders.png',
            'assets/illustrations/better-health.png',
          ][page],
          key: ValueKey(page),
          height: 258,
          fit: BoxFit.contain,
          cacheWidth: 640,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}

class CareIcon extends StatelessWidget {
  final IconData icon;
  const CareIcon(this.icon, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, size: 22),
  );
}

/// Decorative, resolution-independent artwork; never carries essential text.
class CareArtwork extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool completed;
  const CareArtwork({
    super.key,
    this.icon = Icons.medication_rounded,
    this.size = 180,
    this.completed = false,
  });
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _GardenPainter(completed)),
            ),
            Transform.rotate(
              angle: -.12,
              child: Container(
                width: size * .53,
                height: size * .60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * .15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: completed
                        ? const [Color(0xFF7EDDBB), careTeal]
                        : const [Color(0xFFD5C3FF), Color(0xFF7950E8)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: .18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  completed ? Icons.check_rounded : icon,
                  size: size * .32,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              right: size * .09,
              bottom: size * .16,
              child: Container(
                padding: EdgeInsets.all(size * .06),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDBE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFAE3867),
                  size: size * .15,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GardenPainter extends CustomPainter {
  final bool completed;
  const _GardenPainter(this.completed);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    canvas.drawCircle(
      const Offset(100, 100),
      87,
      Paint()..color = (completed ? careTeal : purple).withValues(alpha: .06),
    );
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(100, 169);
      canvas.scale(side, 1);
      final stem = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(67, -20, 71, -104);
      canvas.drawPath(
        stem,
        Paint()
          ..color = careTeal.withValues(alpha: .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (var i = 0; i < 4; i++) {
        canvas.save();
        canvas.translate(48 + i * 6, -14 - i * 21);
        canvas.rotate(.5 + i * .10);
        final leaf = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-14, -30, 7, -34)
          ..quadraticBezierTo(25, -9, 0, 0);
        canvas.drawPath(
          leaf,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFB6E6CC), Color(0xFF48A591)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(const Rect.fromLTWH(-10, -34, 35, 34)),
        );
        canvas.restore();
      }
      canvas.restore();
    }
    for (final point in [
      const Offset(30, 45),
      const Offset(165, 29),
      const Offset(177, 110),
    ]) {
      final star = Path();
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final radius = i.isEven ? 6.0 : 2.0;
        final x = point.dx + math.cos(angle) * radius;
        final y = point.dy + math.sin(angle) * radius;
        if (i == 0) {
          star.moveTo(x, y);
        } else {
          star.lineTo(x, y);
        }
      }
      canvas.drawPath(star..close(), Paint()..color = const Color(0xFFC4A2EE));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GardenPainter oldDelegate) =>
      oldDelegate.completed != completed;
}

/// Leaves Material's keyboard, focus, semantics and ink behavior intact.
class PressScale extends StatefulWidget {
  final Widget child;
  final bool spring;
  const PressScale({super.key, required this.child, this.spring = false});
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => pressed = true),
    onPointerUp: (_) => setState(() => pressed = false),
    onPointerCancel: (_) => setState(() => pressed = false),
    child: AnimatedScale(
      scale: pressed ? .97 : 1,
      duration: motionDuration(context, widget.spring && !pressed ? 450 : 140),
      curve: widget.spring && !pressed ? Curves.elasticOut : Curves.easeOut,
      child: widget.child,
    ),
  );
}

class CareButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool positive;
  const CareButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.positive = false,
  });
  @override
  Widget build(BuildContext context) => PressScale(
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: onPressed == null
            ? null
            : LinearGradient(
                colors: positive
                    ? const [Color(0xFF10895E), Color(0xFF08694F)]
                    : const [Color(0xFF7550E8), Color(0xFF5531CF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: purple.withValues(alpha: .19),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: child,
      ),
    ),
  );
}

class CareProgress extends StatelessWidget {
  final double value;
  final String? label;
  const CareProgress({super.key, required this.value, this.label});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.clamp(0, 1)),
    duration: motionDuration(context, 550),
    curve: Curves.easeOutCubic,
    builder: (context, progress, _) => LinearProgressIndicator(
      value: progress,
      semanticsLabel: label,
      minHeight: 8,
      borderRadius: BorderRadius.circular(20),
      color: careTeal,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
  );
}

/// Used only while actual initialization is pending. Motion stops after entry.
class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: SoftEntrance(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CareArtwork(size: 220),
                const SizedBox(height: 24),
                const Text(
                  'Daryeel',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: careTeal,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      for (final width in [220.0, 170.0, 110.0])
                        Container(
                          height: 12,
                          width: width,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
