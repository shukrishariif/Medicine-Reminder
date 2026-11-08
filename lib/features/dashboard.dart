import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/premium.dart';
import '../core/motion.dart';
import '../data/models.dart';
import '../services/app_controller.dart';
import 'widgets.dart';
import 'wellness_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final today = app.today;
    final taken = today
        .where((d) => d.recordedStatus == DoseStatus.taken)
        .length;
    final remaining = today
        .where(
          (d) => !d.resolved && d.statusAt(DateTime.now()) != DoseStatus.missed,
        )
        .toList();
    final next = remaining.isEmpty ? null : remaining.first;
    final now = DateTime.now();
    return PageBody(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Daryeel',
                style: TextStyle(
                  color: careTeal,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1,
                ),
              ),
            ),
            IconButton(
              tooltip: tr(context, 'Notifications'),
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            IconButton(
              tooltip: tr(context, 'Profile'),
              onPressed: () => context.go('/profile'),
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: lavender,
                child: Text(
                  app.name.isEmpty
                      ? 'D'
                      : app.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: purple,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              now.hour < 18 ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: const Color(0xFFC08000),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    now.hour < 12
                        ? 'Good morning!'
                        : now.hour < 18
                        ? 'Good afternoon!'
                        : 'Good evening!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (app.name.isNotEmpty)
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  LocalizedText(
                    'Take care of yourself today',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel(context, now, 'EEEE, d MMMM'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        DailyProgressCard(
          taken: taken,
          total: today.length,
          onTap: () => context.go('/history'),
        ),
        const SizedBox(height: 16),
        if (next != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? const [Color(0xFF443065), Color(0xFF302550)]
                    : const [Color(0xFFE9D6FF), Color(0xFFD9D2FF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12, left: 4, right: 4),
                  child: LocalizedText(
                    'Next Medicine',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const PillIcon(size: 56),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    next.name,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    next.dosage,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    timeLabel(
                                      context,
                                      next.snoozedUntil ?? next.scheduled,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: tr(context, 'Medicine reminder'),
                              onPressed: () => context.push(
                                '/alarm/${Uri.encodeComponent(next.id)}',
                              ),
                              icon: const Icon(
                                Icons.notifications_active_outlined,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: CareButton(
                            onPressed: () => completeDose(context, app, next),
                            child: const LocalizedText('Take Now'),
                          ),
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => snoozeDialog(context, app, next),
                              child: const LocalizedText('Snooze'),
                            ),
                            TextButton(
                              onPressed: () => context.push(
                                '/alarm/${Uri.encodeComponent(next.id)}',
                              ),
                              child: const LocalizedText('Medicine reminder'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!app.reminders.allowed ||
            app.settings['notifications'] == false) ...[
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFFFF0D8),
            child: ListTile(
              leading: const Icon(
                Icons.notifications_off_outlined,
                color: Color(0xFF815300),
              ),
              title: const LocalizedText(
                'Reminders may not appear',
                style: TextStyle(
                  color: Color(0xFF815300),
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: LocalizedText(
                app.reminders.supported
                    ? 'Tap to review notification and alarm permissions.'
                    : 'Device reminders are available in the Android app.',
                style: const TextStyle(color: Color(0xFF815300)),
              ),
              onTap: () => context.push('/settings'),
            ),
          ),
        ],
        if (today.isEmpty) ...[
          const SizedBox(height: 16),
          EmptyState(
            title: 'Your routine starts here',
            description: 'Add your first medicine',
            action: CareButton(
              onPressed: () => context.push('/medicine/new'),
              child: const LocalizedText('Add medicine'),
            ),
          ),
        ],
        SectionTitle(
          "Today's schedule",
          action: TextButton(
            onPressed: () => context.go('/schedule'),
            child: const LocalizedText('See all'),
          ),
        ),
        ...today.map(
          (d) => DoseTile(
            key: ValueKey(d.id),
            dose: d,
            onTake: d.resolved ? null : () => completeDose(context, app, d),
            onTap: () => context.push('/alarm/${Uri.encodeComponent(d.id)}'),
          ),
        ),
        const SectionTitle('Weekly adherence'),
        AdherenceChart(app: app),
      ],
    );
  }
}

Future<void> completeDose(
  BuildContext context,
  AppController app,
  Dose dose,
) async {
  if (dose.scheduled.isAfter(DateTime.now()) &&
      !await confirm(
        context,
        'Mark as taken',
        trf(context, 'earlyDose', {'time': timeLabel(context, dose.scheduled)}),
      )) {
    return;
  }
  await app.updateDose(dose, DoseStatus.taken);
  if (context.mounted && app.error == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SoftEntrance(
              child: Icon(Icons.check_circle_rounded, color: Color(0xFF8FE0BE)),
            ),
            const SizedBox(width: 12),
            Expanded(child: LocalizedText(tr(context, 'Taken'))),
          ],
        ),
      ),
    );
  }
}

Future<void> snoozeDialog(
  BuildContext context,
  AppController app,
  Dose dose,
) async {
  final minutes = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    backgroundColor: const Color(0xFFFAF7FF),
    builder: (ctx) => Theme(
      data: appTheme(Brightness.light),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: LocalizedText(
                  tr(ctx, 'Snooze reminder'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final m in [5, 10, 15])
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: m == 10 ? lavender : Colors.white,
                        side: BorderSide(
                          color: m == 10 ? purple : const Color(0xFFE7E0F5),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, m),
                      child: LocalizedText('$m ${tr(ctx, 'min')}'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const LocalizedText('Cancel'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
  if (minutes != null) {
    await app.updateDose(dose, DoseStatus.snoozed, snoozeMinutes: minutes);
  }
}

class AdherenceChart extends StatelessWidget {
  final AppController app;
  const AdherenceChart({super.key, required this.app});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final day = DateTime.now().subtract(Duration(days: 6 - i));
          final doses = app
              .doses(day, day)
              .where((d) => !d.scheduled.isAfter(DateTime.now()))
              .toList();
          final taken = doses
              .where((d) => d.recordedStatus == DoseStatus.taken)
              .length;
          final ratio = doses.isEmpty ? 0.0 : taken / doses.length;
          return Expanded(
            child: Semantics(
              label: '${dateLabel(context, day)}: $taken / ${doses.length}',
              child: Column(
                children: [
                  LocalizedText(
                    doses.isEmpty ? '—' : '${(ratio * 100).round()}%',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 72,
                    width: 18,
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      color: lavender,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnimatedContainer(
                      duration: motionDuration(context, 600),
                      curve: Curves.easeOutCubic,
                      height: 72 * ratio,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [careTeal, Color(0xFF79D3B2)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  LocalizedText(
                    dateLabel(context, day, 'EE'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ),
  );
}

class ScheduleScreen extends ConsumerStatefulWidget {
  final bool history;
  const ScheduleScreen({super.key, this.history = false});
  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime date = dayOnly(DateTime.now());
  String range = 'Day', filter = 'All';
  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final start = range == 'Week'
        ? date.subtract(Duration(days: date.weekday - 1))
        : range == 'Month'
        ? DateTime(date.year, date.month)
        : date;
    final end = range == 'Week'
        ? DateTime(start.year, start.month, start.day + 6)
        : range == 'Month'
        ? DateTime(date.year, date.month + 1, 0)
        : date;
    final all = app
        .doses(start, end)
        .where(
          (d) =>
              !widget.history ||
              !d.scheduled.isAfter(DateTime.now()) ||
              d.resolved,
        )
        .toList();
    final list = all
        .where(
          (d) =>
              filter == 'All' ||
              statusLabel(d.statusAt(DateTime.now())) == filter,
        )
        .toList();
    final taken = all.where((d) => d.recordedStatus == DoseStatus.taken).length;
    return PageBody(
      children: [
        Row(
          children: [
            Expanded(
              child: LocalizedText(
                tr(context, widget.history ? 'History' : 'Schedule'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: () => context.push('/medicines'),
              tooltip: tr(context, 'Medicines'),
              icon: const Icon(Icons.medication_outlined),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SegmentedButton<String>(
          segments: ['Day', 'Week', 'Month']
              .map(
                (r) => ButtonSegment(
                  value: r,
                  label: LocalizedText(tr(context, r)),
                ),
              )
              .toList(),
          selected: {range},
          onSelectionChanged: (v) => setState(() => range = v.first),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              tooltip: tr(context, 'Previous'),
              onPressed: () => setState(
                () => date = range == 'Month'
                    ? DateTime(date.year, date.month - 1)
                    : date.subtract(Duration(days: range == 'Week' ? 7 : 1)),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final value = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (value != null) {
                    setState(() => date = value);
                  }
                },
                child: LocalizedText(
                  dateLabel(
                    context,
                    date,
                    range == 'Month' ? 'MMMM yyyy' : 'EEE, d MMM yyyy',
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: tr(context, 'Next'),
              onPressed: () => setState(
                () => date = range == 'Month'
                    ? DateTime(date.year, date.month + 1)
                    : date.add(Duration(days: range == 'Week' ? 7 : 1)),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (range == 'Month')
          CalendarDatePicker(
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            onDateChanged: (value) => setState(() {
              date = value;
              range = 'Day';
            }),
          ),
        if (range == 'Day') ...[
          WeekStrip(
            selected: date,
            onSelected: (value) => setState(() => date = value),
          ),
          const SizedBox(height: 20),
        ],
        if (widget.history) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    '${all.isEmpty ? 0 : (taken / all.length * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 38,
                      color: purple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  LocalizedText(
                    '$taken / ${all.length} ${tr(context, 'Taken')}',
                  ),
                  const SizedBox(height: 12),
                  CareProgress(
                    value: all.isEmpty ? 0 : taken / all.length,
                    label: tr(context, 'Taken'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                      'All',
                      'Upcoming',
                      'Due now',
                      'Taken',
                      'Skipped',
                      'Missed',
                      'Snoozed',
                    ]
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: LocalizedText(tr(context, s)),
                          selected: filter == s,
                          onSelected: (_) => setState(() => filter = s),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 22),
        if (list.isEmpty)
          const EmptyState(
            title: 'No doses scheduled',
            description: 'Your saved doses will appear here.',
          ),
        for (var i = 0; i < list.length; i++) ...[
          if (i == 0 ||
              dayKey(list[i].scheduled) != dayKey(list[i - 1].scheduled))
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: LocalizedText(
                dateLabel(context, list[i].scheduled),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          DoseTile(
            key: ValueKey(list[i].id),
            dose: list[i],
            onTake: list[i].resolved
                ? null
                : () => completeDose(context, app, list[i]),
            onTap: () =>
                context.push('/alarm/${Uri.encodeComponent(list[i].id)}'),
          ),
        ],
        if (widget.history) ...[
          const SectionTitle('Weekly adherence'),
          AdherenceChart(app: app),
        ],
      ],
    );
  }
}

class AlarmScreen extends ConsumerWidget {
  final String id;
  const AlarmScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final candidates = app
        .doses(
          DateTime.now().subtract(const Duration(days: 366)),
          DateTime.now().add(const Duration(days: 366)),
        )
        .where((d) => d.id == id);
    final dose =
        app.records[id] ?? (candidates.isEmpty ? null : candidates.first);
    if (dose == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: LocalizedText(
            id == 'test'
                ? 'Your test reminder worked.'
                : 'This reminder is no longer active.',
          ),
        ),
      );
    }
    final medicines = app.medicines.where((m) => m.id == dose.medicineId);
    final taken = dose.recordedStatus == DoseStatus.taken;
    return Theme(
      data: appTheme(Brightness.dark),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF181832),
          appBar: AppBar(
            backgroundColor: const Color(0xFF29204E),
            title: const LocalizedText('Medicine reminder'),
            leading: IconButton(
              tooltip: tr(context, 'Close'),
              icon: const Icon(Icons.close_rounded),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF30205B),
                  Color(0xFF1C1A40),
                  Color(0xFF131B32),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(26, 28, 26, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: AlarmIllustration(completed: taken)),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: motionDuration(context, 300),
                          child: LocalizedText(
                            taken
                                ? 'Great!'
                                : dose.resolved
                                ? statusLabel(dose.recordedStatus)
                                : 'Time for your medicine!',
                            key: ValueKey(dose.recordedStatus),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (taken) ...[
                          const SizedBox(height: 8),
                          const LocalizedText(
                            'You took your medicine',
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 22),
                        Text(
                          dose.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dose.dosage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          timeLabel(context, dose.scheduled),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateLabel(context, dose.scheduled),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFD3CCE8)),
                        ),
                        if (dose.snoozedUntil != null && !dose.resolved) ...[
                          const SizedBox(height: 12),
                          Text(
                            '${tr(context, 'Snoozed')} · ${timeLabel(context, dose.snoozedUntil!)}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (dose.completedAt != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '${dateLabel(context, dose.completedAt!)} · ${timeLabel(context, dose.completedAt!)}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (medicines.isNotEmpty &&
                            medicines.first.instructions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              medicines.first.instructions,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 28),
                        if (!dose.resolved) ...[
                          CareButton(
                            onPressed: () => completeDose(context, app, dose),
                            child: const LocalizedText('Take Now'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    IconButton.filledTonal(
                                      tooltip: tr(context, 'Snooze'),
                                      style: IconButton.styleFrom(
                                        minimumSize: const Size(60, 60),
                                        backgroundColor: Colors.white
                                            .withValues(alpha: .10),
                                      ),
                                      onPressed: () =>
                                          snoozeDialog(context, app, dose),
                                      icon: const Icon(
                                        Icons.snooze_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const LocalizedText(
                                      'Snooze',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    IconButton.filledTonal(
                                      tooltip: tr(context, 'Skip dose'),
                                      style: IconButton.styleFrom(
                                        minimumSize: const Size(60, 60),
                                        backgroundColor: Colors.white
                                            .withValues(alpha: .10),
                                      ),
                                      onPressed: () async {
                                        if (await confirm(
                                          context,
                                          'Skip dose',
                                          'Record this dose as skipped?',
                                        )) {
                                          await app.updateDose(
                                            dose,
                                            DoseStatus.skipped,
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const LocalizedText(
                                      'Skip dose',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else
                          CareButton(
                            onPressed: () => context.canPop()
                                ? context.pop()
                                : context.go('/home'),
                            child: const LocalizedText('Done'),
                          ),
                        const SizedBox(height: 18),
                        if (medicines.isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                context.push('/medicine/${dose.medicineId}'),
                            child: const LocalizedText('Edit medicine'),
                          ),
                        const SizedBox(height: 16),
                        const LocalizedText(
                          'Follow the instructions provided by your healthcare professional. Daryeel records your routine; it does not change your prescribed dose.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD3CCE8),
                            height: 1.5,
                          ),
                        ),
                        if (app.error != null) LocalizedText(app.error!),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final list = app.today.where((d) => !d.resolved).toList();
    return Scaffold(
      appBar: AppBar(title: LocalizedText(tr(context, 'Notifications'))),
      body: PageBody(
        children: [
          ListTile(
            leading: const Icon(Icons.tune),
            title: LocalizedText(tr(context, 'Alarm settings')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const EmptyState(
              title: 'No doses scheduled',
              description: 'Your reminders will appear here.',
            ),
          ...list.map(
            (d) => DoseTile(
              dose: d,
              onTap: () => context.push('/alarm/${Uri.encodeComponent(d.id)}'),
            ),
          ),
        ],
      ),
    );
  }
}
