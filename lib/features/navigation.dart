import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/motion.dart';
import '../core/premium.dart';
import '../core/strings.dart';
import '../core/theme.dart';

class AddMedicineButton extends StatelessWidget {
  const AddMedicineButton({super.key});
  @override
  Widget build(BuildContext context) => PressScale(
    spring: true,
    child: Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: .30),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB382FF), Color(0xFF8241F9), Color(0xFF5624D8)],
            ),
          ),
          child: IconButton(
            key: const ValueKey('add-medicine'),
            tooltip: tr(context, 'Add medicine'),
            onPressed: () => context.push('/medicine/new'),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
          ),
        ),
      ),
    ),
  );
}

class DaryeelNavigation extends StatelessWidget {
  final int index;
  const DaryeelNavigation({super.key, required this.index});
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: .07),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _item(context, 0, Icons.home_outlined, Icons.home_rounded, 'Home'),
          _item(
            context,
            1,
            Icons.calendar_month_outlined,
            Icons.calendar_month_rounded,
            'Schedule',
          ),
          const SizedBox(width: 70),
          _item(
            context,
            2,
            Icons.history_rounded,
            Icons.history_rounded,
            'History',
          ),
          _item(
            context,
            3,
            Icons.person_outline_rounded,
            Icons.person_rounded,
            'Profile',
          ),
        ],
      ),
    ),
  );
  Widget _item(
    BuildContext context,
    int destination,
    IconData icon,
    IconData active,
    String title,
  ) {
    final selected = index == destination;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(
            ['/home', '/schedule', '/history', '/profile'][destination],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: motionDuration(context, 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: .09)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      selected ? active : icon,
                      size: 23,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LocalizedText(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
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
}
