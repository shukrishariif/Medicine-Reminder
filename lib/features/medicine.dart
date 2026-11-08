import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/strings.dart';
import '../core/premium.dart';
import '../core/motion.dart';
export 'medicine_editor.dart';
import '../services/app_controller.dart';
import 'widgets.dart';
import 'medicine_avatar.dart';

class MedicineListScreen extends ConsumerStatefulWidget {
  const MedicineListScreen({super.key});
  @override
  ConsumerState<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends ConsumerState<MedicineListScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final medicines = ref
        .watch(appProvider)
        .medicines
        .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: LocalizedText(tr(context, 'Medicines')),
        actions: [
          IconButton(
            onPressed: () => context.push('/medicine/new'),
            tooltip: tr(context, 'Add medicine'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: PageBody(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr(context, 'Search medicines'),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 20),
          if (medicines.isEmpty)
            const EmptyState(
              title: 'No medicines found',
              description: 'Add your first medicine',
            ),
          ...medicines.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  leading: MedicineAvatar(
                    photo: m.photo,
                    color: m.color,
                    size: 48,
                  ),
                  title: Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: LocalizedText(
                    '${m.dosage}${m.paused ? ' · ${tr(context, 'Paused')}' : ''}${m.archived ? ' · ${tr(context, 'Archived')}' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/medicine/${m.id}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MedicineDetails extends ConsumerStatefulWidget {
  final String id;
  const MedicineDetails({super.key, required this.id});
  @override
  ConsumerState<MedicineDetails> createState() => _MedicineDetailsState();
}

class _MedicineDetailsState extends ConsumerState<MedicineDetails> {
  bool saving = false;
  Future<void> update(Future<void> Function() action) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await action();
      if (!mounted) return;
      final error = ref.read(appProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: LocalizedText(error ?? 'Changes saved')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final matches = app.medicines.where((m) => m.id == widget.id);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: LocalizedText('Medicine no longer available.'),
        ),
      );
    }
    final m = matches.first;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    void edit() => context.push('/edit/${m.id}');
    final duration =
        m.treatmentDays ??
        (m.end == null
            ? null
            : DateTime.utc(m.end!.year, m.end!.month, m.end!.day)
                      .difference(
                        DateTime.utc(m.start.year, m.start.month, m.start.day),
                      )
                      .inDays +
                  1);
    final durationText = duration == null
        ? tr(context, 'No end date')
        : '$duration ${tr(context, 'days')}';
    final times = m.times
        .map((t) => TimeOfDay(hour: t ~/ 60, minute: t % 60).format(context))
        .join(' · ');
    Future<void> refill(bool enabled) async {
      DateTime? value;
      if (enabled) {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: DateTime(now.year + 10),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(
            now.add(const Duration(hours: 1)),
          ),
        );
        if (time == null || !context.mounted) return;
        value = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        if (!value.isAfter(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: LocalizedText('Choose a future refill time.')),
          );
          return;
        }
      }
      await update(
        () => app.saveMedicine(
          m.change({'refillAt': value?.toUtc().toIso8601String()}),
        ),
      );
    }

    Future<void> delete() async {
      if (await confirm(
        context,
        'Delete',
        trf(context, 'deleteMedicine', {'name': m.name}),
      )) {
        await update(() => app.deleteMedicine(m));
        if (context.mounted && app.error == null) context.go('/home');
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const LocalizedText('Medicine details'),
        actions: [
          PopupMenuButton<String>(
            enabled: !saving,
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (value) async {
              if (value == 'pause') {
                await update(
                  () => app.saveMedicine(m.change({'paused': !m.paused})),
                );
              } else if (value == 'archive') {
                await update(
                  () => app.saveMedicine(m.change({'archived': !m.archived})),
                );
              } else {
                await delete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pause',
                child: LocalizedText(m.paused ? 'Resume' : 'Pause'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: LocalizedText('Delete'),
              ),
              PopupMenuItem(
                value: 'archive',
                child: LocalizedText(
                  m.archived ? 'Restore medicine' : 'Archive medicine',
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: dark
                ? const [Color(0xFF30223F), Color(0xFF181422)]
                : const [
                    Color(0xFFE9DAFF),
                    Color(0xFFFAF8FF),
                    Color(0xFFF5F2FF),
                  ],
            stops: dark ? const [0, 1] : const [0, .45, 1],
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  SoftEntrance(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .7),
                              width: 2,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                accent.withValues(alpha: .08),
                                accent.withValues(alpha: .19),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: .12),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: m.photo.isNotEmpty
                              ? MedicineAvatar(
                                  photo: m.photo,
                                  color: m.color,
                                  size: 140,
                                )
                              : CareArtwork(
                                  size: 140,
                                  icon: m.type == 'Syrup' || m.type == 'Drops'
                                      ? Icons.local_pharmacy_rounded
                                      : Icons.medication_rounded,
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          m.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          avatar: Icon(
                            m.type == 'Syrup' || m.type == 'Drops'
                                ? Icons.water_drop_outlined
                                : Icons.medication_outlined,
                            color: accent,
                          ),
                          label: LocalizedText(m.type),
                          backgroundColor: accent.withValues(alpha: .10),
                          side: BorderSide.none,
                        ),
                        if (m.paused || m.archived)
                          LocalizedText(m.archived ? 'Archived' : 'Paused'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DetailsCard(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final items = [
                          _DetailMetric(
                            Icons.inventory_2_outlined,
                            'Dose',
                            m.dosage,
                          ),
                          _DetailMetric(
                            Icons.restaurant_rounded,
                            'Instructions',
                            tr(context, m.food),
                          ),
                          _DetailMetric(
                            Icons.calendar_month_outlined,
                            'Duration',
                            durationText,
                          ),
                        ];
                        if (constraints.maxWidth < 320 ||
                            MediaQuery.textScalerOf(context).scale(16) > 22) {
                          return Column(
                            children: [
                              for (final item in items)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: item,
                                ),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in items) Expanded(child: item),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailsCard(
                    child: Row(
                      children: [
                        CareIcon(Icons.notifications_active_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LocalizedText(
                                'Refill reminder',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.refillAt == null
                                    ? tr(context, 'Not set')
                                    : '${dateLabel(context, m.refillAt!)} · ${timeLabel(context, m.refillAt!)}',
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: m.refillAt != null,
                          onChanged: saving ? null : refill,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 26,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: LocalizedText(
                          'Schedule',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailsCard(
                    child: Column(
                      children: [
                        _ScheduleRow(
                          Icons.event_repeat,
                          'Frequency',
                          m.intervalDays == 1
                              ? tr(context, 'Daily')
                              : '${tr(context, 'Interval in days')}: ${m.intervalDays}',
                          edit,
                        ),
                        _ScheduleRow(
                          Icons.schedule,
                          'Reminder times',
                          times,
                          edit,
                        ),
                        _ScheduleRow(
                          Icons.date_range_outlined,
                          'Duration',
                          durationText,
                          edit,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 8,
                          children: [
                            for (var day = 1; day <= 7; day++)
                              Semantics(
                                selected: m.weekdays.contains(day),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: accent.withValues(alpha: .12),
                                    ),
                                    gradient: m.weekdays.contains(day)
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFFAA6BF5),
                                              Color(0xFF7736DE),
                                            ],
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (m.weekdays.contains(day))
                                        const Icon(
                                          Icons.check,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                      Text(
                                        dateLabel(
                                          context,
                                          DateTime(2026, 10, 18 + day),
                                          'EEE',
                                        ),
                                        style: TextStyle(
                                          color: m.weekdays.contains(day)
                                              ? Colors.white
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${dateLabel(context, m.start)} → ${m.end == null ? tr(context, 'No end date') : dateLabel(context, m.end!)}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if ([
                    m.strength,
                    m.category,
                    m.instructions,
                    m.notes,
                  ].any((v) => v.isNotEmpty)) ...[
                    const SizedBox(height: 14),
                    _DetailsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in {
                            'Strength': m.strength,
                            'Category': m.category,
                            'Instructions': m.instructions,
                            'Notes': m.notes,
                          }.entries)
                            if (entry.value.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${tr(context, entry.key)}: ${entry.value}',
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  CareButton(
                    onPressed: saving ? null : edit,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 12),
                        Flexible(child: LocalizedText('Edit medicine')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dark
                          ? const Color(0xFFFFA5AB)
                          : const Color(0xFFB52239),
                      backgroundColor: dark
                          ? const Color(0xFF39222D)
                          : const Color(0xFFFFF0F2),
                      side: const BorderSide(color: Color(0xFFFFC5CF)),
                      padding: const EdgeInsets.all(18),
                    ),
                    onPressed: saving ? null : delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const LocalizedText('Delete Medicine'),
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

class _DetailsCard extends StatelessWidget {
  final Widget child;
  const _DetailsCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .85),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .09),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7750C9).withValues(alpha: .06),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class _DetailMetric extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailMetric(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        LocalizedText(label, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ],
    ),
  );
}

class _ScheduleRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  const _ScheduleRow(this.icon, this.label, this.value, this.onTap);
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: LocalizedText(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(value),
    trailing: const Icon(Icons.chevron_right),
  );
}
