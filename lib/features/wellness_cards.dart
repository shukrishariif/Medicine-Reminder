import 'package:flutter/material.dart';
import '../core/motion.dart';
import '../core/premium.dart';
import '../core/strings.dart';
import '../core/theme.dart';

class PillIcon extends StatelessWidget {
  final Color color;
  final double size;
  const PillIcon({super.key, this.color = purple, this.size = 48});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .2), color.withValues(alpha: .04)],
        ),
      ),
      child: Transform.rotate(
        angle: .7,
        child: Container(
          width: size * .34,
          height: size * .65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .24),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size),
            child: Column(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          color.withValues(alpha: .12),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: .55), color, color],
                      ),
                    ),
                    child: const SizedBox.expand(),
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

class DailyProgressCard extends StatelessWidget {
  final int taken, total;
  final VoidCallback onTap;
  const DailyProgressCard({
    super.key,
    required this.taken,
    required this.total,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: total == 0 ? 0 : taken / total,
                      ),
                      duration: motionDuration(context, 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        color: careTeal,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .13),
                        semanticsLabel: tr(context, 'doses taken today'),
                      ),
                    ),
                  ),
                  Text(
                    '${total == 0 ? 0 : (taken / total * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LocalizedText(
                    "Today's Progress",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$taken / $total ${tr(context, 'Taken')}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    ),
  );
}

class AlarmIllustration extends StatelessWidget {
  final bool completed;
  const AlarmIllustration({super.key, required this.completed});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SoftEntrance(
      child: SizedBox.square(
        dimension: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-.4, -.5),
                  colors: [
                    Color(0xFFE8CEFF),
                    Color(0xFF9F6AED),
                    Color(0xFF6330AF),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .25),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB564FF).withValues(alpha: .24),
                    blurRadius: 38,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: motionDuration(context, 500),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: completed
                  ? Container(
                      key: const ValueKey('success'),
                      width: 112,
                      height: 112,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF82EDBA), Color(0xFF0A9666)],
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 74,
                      ),
                    )
                  : const PillIcon(
                      key: ValueKey('pill'),
                      size: 126,
                      color: Color(0xFFF2E7FF),
                    ),
            ),
            const Positioned(
              top: 9,
              right: 22,
              child: Icon(
                Icons.auto_awesome,
                size: 23,
                color: Color(0xFFF0D0FF),
              ),
            ),
            const Positioned(
              left: 6,
              top: 47,
              child: Icon(
                Icons.auto_awesome,
                size: 18,
                color: Color(0xFFFFD887),
              ),
            ),
            const Positioned(
              left: 14,
              bottom: 9,
              child: Icon(
                Icons.spa_rounded,
                size: 42,
                color: Color(0xFF91D5B7),
              ),
            ),
            const Positioned(
              right: 13,
              bottom: 8,
              child: Icon(
                Icons.spa_rounded,
                size: 32,
                color: Color(0xFFBCDAA9),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
