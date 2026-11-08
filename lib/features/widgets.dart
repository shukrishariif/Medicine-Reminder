import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/motion.dart';
import '../core/premium.dart';
import '../core/somali_material.dart';
import '../data/models.dart';
import 'wellness_cards.dart';

String dateLabel(
  BuildContext context,
  DateTime date, [
  String pattern = 'EEE, d MMM',
]) => Localizations.localeOf(context).languageCode == 'so'
    ? formatSomaliDate(date, pattern)
    : DateFormat(
        pattern,
        Localizations.localeOf(context).languageCode,
      ).format(date);
String timeLabel(BuildContext context, DateTime date) =>
    TimeOfDay.fromDateTime(date).format(context);
String statusLabel(DoseStatus status) => switch (status) {
  DoseStatus.pending => 'Upcoming',
  DoseStatus.due => 'Due now',
  DoseStatus.taken => 'Taken',
  DoseStatus.skipped => 'Skipped',
  DoseStatus.missed => 'Missed',
  DoseStatus.snoozed => 'Snoozed',
};

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, .38, 1],
        colors: Theme.of(context).brightness == Brightness.dark
            ? const [Color(0xFF1D2330), Color(0xFF191523), Color(0xFF161421)]
            : const [Color(0xFFEAF5F5), Color(0xFFF8F6FF), Color(0xFFF5F0FF)],
      ),
    ),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            for (var i = 0; i < children.length; i++)
              SoftEntrance(
                key: children[i].key == null ? null : ValueKey(children[i].key),
                order: i,
                child: children[i] is ListTile || children[i] is SwitchListTile
                    ? Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: children[i],
                        ),
                      )
                    : children[i],
              ),
          ],
        ),
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionTitle(this.title, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 14),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final titleRow = Row(
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsetsDirectional.only(end: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: LocalizedText(
                tr(context, title),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (action != null && !stacked) Flexible(child: action!),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleRow,
            if (action != null && stacked)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: action!,
              ),
          ],
        );
      },
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, description;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SoftEntrance(
            child: CareArtwork(icon: Icons.spa_rounded, size: 128),
          ),
          const SizedBox(height: 18),
          LocalizedText(
            tr(context, title),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          LocalizedText(tr(context, description), textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

class DoseTile extends StatelessWidget {
  final Dose dose;
  final VoidCallback onTap;
  final VoidCallback? onTake;
  const DoseTile({
    super.key,
    required this.dose,
    required this.onTap,
    this.onTake,
  });
  @override
  Widget build(BuildContext context) {
    final status = dose.statusAt(DateTime.now());
    final taken = status == DoseStatus.taken;
    final missed = status == DoseStatus.missed;
    final accent = taken
        ? careTeal
        : missed
        ? const Color(0xFFA64332)
        : purple;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressScale(
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: motionDuration(context, 320),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Container(
                      key: ValueKey(status),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: taken ? mint : lavender,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: taken
                          ? Icon(Icons.check_rounded, color: accent, size: 25)
                          : PillIcon(color: accent, size: 46),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dose.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dose.dosage,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              timeLabel(
                                context,
                                dose.snoozedUntil ?? dose.scheduled,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            AnimatedContainer(
                              duration: motionDuration(context, 280),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: taken
                                    ? mint
                                    : missed
                                    ? const Color(0xFFFFE9DF)
                                    : lavender,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: LocalizedText(
                                tr(context, statusLabel(status)),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (onTake != null && !dose.resolved)
                    IconButton(
                      tooltip: '${tr(context, 'Take Now')} · ${dose.name}',
                      onPressed: onTake,
                      icon: Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.outline,
                      size: 20,
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

/// A scrollable date strip retains generous touch targets at large text sizes.
class WeekStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  const WeekStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) {
    final start = selected.subtract(Duration(days: selected.weekday - 1));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (i) {
          final day = DateTime(start.year, start.month, start.day + i);
          final active = dayKey(day) == dayKey(selected);
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Semantics(
              selected: active,
              label: dateLabel(context, day, 'EEEE, d MMMM'),
              child: PressScale(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: active
                        ? purple
                        : Theme.of(context).cardColor,
                    foregroundColor: active
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(
                      color: active
                          ? purple
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () => onSelected(day),
                  child: Column(
                    children: [
                      Text(dateLabel(context, day, 'EE')),
                      const SizedBox(height: 6),
                      Text(
                        '${day.day}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: LocalizedText(tr(ctx, title)),
        content: LocalizedText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: LocalizedText(tr(ctx, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: LocalizedText(tr(ctx, 'Continue')),
          ),
        ],
      ),
    ) ??
    false;
