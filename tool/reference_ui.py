from pathlib import Path
p=Path('lib/features/dashboard.dart'); s=p.read_text(encoding='utf-8')
s=s.replace("import 'widgets.dart';", "import 'widgets.dart';\nimport 'wellness_cards.dart';")
a=s.index('class HomeScreen'); b=s.index('Future<void> completeDose',a)
s=s[:a]+'''class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final today = app.today;
    final taken = today.where((d) => d.recordedStatus == DoseStatus.taken).length;
    final remaining = today.where((d) => !d.resolved && d.statusAt(DateTime.now()) != DoseStatus.missed).toList();
    final next = remaining.isEmpty ? null : remaining.first;
    final now = DateTime.now();
    return PageBody(children: [
      Row(children: [
        const Expanded(child: Text('Daryeel', style: TextStyle(color: careTeal,
          fontSize: 28, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, letterSpacing: -1))),
        IconButton(tooltip: tr(context, 'Notifications'),
          onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_none_rounded)),
        IconButton(tooltip: tr(context, 'Profile'), onPressed: () => context.go('/profile'),
          icon: CircleAvatar(radius: 18, backgroundColor: lavender,
            child: Text(app.name.isEmpty ? 'D' : app.name.characters.first.toUpperCase(),
              style: const TextStyle(color: purple, fontWeight: FontWeight.w800)))),
      ]),
      const SizedBox(height: 22),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(now.hour < 18 ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          color: const Color(0xFFC08000), size: 32),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LocalizedText(now.hour < 12 ? 'Good morning!' : now.hour < 18 ? 'Good afternoon!' : 'Good evening!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          if (app.name.isNotEmpty) Text(app.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          LocalizedText('Take care of yourself today', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(dateLabel(context, now, 'EEEE, d MMMM'), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ])),
      ]),
      const SizedBox(height: 20),
      DailyProgressCard(taken: taken, total: today.length, onTap: () => context.go('/history')),
      const SizedBox(height: 16),
      if (next != null) Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF443065), Color(0xFF302550)]
              : const [Color(0xFFE9D6FF), Color(0xFFD9D2FF)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Padding(padding: EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: LocalizedText('Next Medicine', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Row(children: [
              const PillIcon(size: 56), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(next.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3), Text(next.dosage, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 3),
                Text(timeLabel(context, next.snoozedUntil ?? next.scheduled),
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
              ])),
              IconButton(tooltip: tr(context, 'Medicine reminder'),
                onPressed: () => context.push('/alarm/${Uri.encodeComponent(next.id)}'),
                icon: const Icon(Icons.notifications_active_outlined, size: 22)),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: CareButton(
              onPressed: () => completeDose(context, app, next), child: const LocalizedText('Take Now'))),
            Wrap(alignment: WrapAlignment.center, children: [
              TextButton(onPressed: () => snoozeDialog(context, app, next), child: const LocalizedText('Snooze')),
              TextButton(onPressed: () => context.push('/alarm/${Uri.encodeComponent(next.id)}'),
                child: const LocalizedText('Medicine reminder')),
            ]),
          ]))),
        ]),
      ),
      if (!app.reminders.allowed || app.settings['notifications'] == false) ...[
        const SizedBox(height: 12),
        Card(color: const Color(0xFFFFF0D8), child: ListTile(
          leading: const Icon(Icons.notifications_off_outlined, color: Color(0xFF815300)),
          title: const LocalizedText('Reminders may not appear', style: TextStyle(color: Color(0xFF815300), fontWeight: FontWeight.w700)),
          subtitle: LocalizedText(app.reminders.supported
            ? 'Tap to review notification and alarm permissions.' : 'Device reminders are available in the Android app.',
            style: const TextStyle(color: Color(0xFF815300))),
          onTap: () => context.push('/settings'),
        )),
      ],
      if (today.isEmpty) ...[
        const SizedBox(height: 16),
        EmptyState(title: 'Your routine starts here', description: 'Add your first medicine',
          action: CareButton(onPressed: () => context.push('/medicine/new'), child: const LocalizedText('Add medicine'))),
      ],
      SectionTitle("Today's schedule", action: TextButton(onPressed: () => context.go('/schedule'), child: const LocalizedText('See all'))),
      ...today.map((d) => DoseTile(key: ValueKey(d.id), dose: d,
        onTake: d.resolved ? null : () => completeDose(context, app, d),
        onTap: () => context.push('/alarm/${Uri.encodeComponent(d.id)}'))),
      const SectionTitle('Weekly adherence'), AdherenceChart(app: app),
    ]);
  }
}

''' + s[b:]
p.write_text(s,encoding='utf-8')
