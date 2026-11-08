import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/motion.dart';
import '../core/premium.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../services/app_controller.dart';
import 'widgets.dart';
import 'medicine_avatar.dart';

class MedicineEditor extends ConsumerStatefulWidget {
  final String? id;
  const MedicineEditor({super.key, this.id});
  @override
  ConsumerState<MedicineEditor> createState() => _MedicineEditorState();
}

class _MedicineEditorState extends ConsumerState<MedicineEditor> {
  final name = TextEditingController(),
      dosage = TextEditingController(),
      strength = TextEditingController(),
      category = TextEditingController(),
      instructions = TextEditingController(),
      notes = TextEditingController(),
      interval = TextEditingController(text: '2'),
      duration = TextEditingController();
  final scroll = ScrollController();
  final form = GlobalKey<FormState>();
  late String id;
  String type = 'Tablet',
      food = 'No preference',
      frequency = 'Daily',
      photo = '';
  int step = 0, repeats = 0, color = 0xFF6240D7;
  List<int> times = [480], days = [1, 2, 3, 4, 5, 6, 7];
  DateTime start = dayOnly(DateTime.now());
  DateTime? end, refillAt;
  bool reminders = true,
      paused = false,
      archived = false,
      saving = false,
      picking = false;
  String? error;
  static const titles = [
    'Medicine Information',
    'Dosage & Timing',
    'Additional Details',
    'Review & Save',
  ];
  static const types = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Liquid',
    'Injection',
    'Drops',
    'Inhaler',
    'Cream',
    'Other',
  ];
  static const colors = [
    0xFF6240D7,
    0xFF2575CA,
    0xFF23875D,
    0xFFC68A14,
    0xFFD24784,
  ];

  @override
  void initState() {
    super.initState();
    id = widget.id ?? newId();
    final matches = ref.read(appProvider).medicines.where((m) => m.id == id);
    if (matches.isNotEmpty) {
      final m = matches.first;
      name.text = m.name;
      dosage.text = m.dosage;
      strength.text = m.strength;
      category.text = m.category;
      instructions.text = m.instructions;
      notes.text = m.notes;
      type = m.type;
      photo = m.photo;
      color = m.color;
      food = m.food;
      times = [...m.times];
      days = [...m.weekdays];
      start = m.start;
      end = m.end;
      reminders = m.reminders;
      repeats = m.repeats;
      paused = m.paused;
      archived = m.archived;
      refillAt = m.refillAt;
      duration.text = m.treatmentDays?.toString() ?? '';
      frequency = m.intervalDays > 1
          ? 'Every N days'
          : days.length == 7
          ? 'Daily'
          : 'Specific weekdays';
      interval.text = '${m.intervalDays > 1 ? m.intervalDays : 2}';
    }
  }

  @override
  void dispose() {
    for (final c in [
      name,
      dosage,
      strength,
      category,
      instructions,
      notes,
      interval,
      duration,
    ]) {
      c.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  Medicine get medicine => Medicine(
    id: id,
    name: name.text.trim(),
    dosage: dosage.text.trim(),
    type: type,
    strength: strength.text.trim(),
    category: category.text.trim(),
    notes: notes.text.trim(),
    instructions: instructions.text.trim(),
    food: food,
    photo: photo,
    color: color,
    times: [...times]..sort(),
    weekdays: frequency == 'Specific weekdays'
        ? [...days]
        : const [1, 2, 3, 4, 5, 6, 7],
    start: start,
    end: end,
    intervalDays: frequency == 'Every N days'
        ? int.tryParse(interval.text) ?? 0
        : 1,
    reminders: reminders,
    repeats: repeats,
    refillAt: refillAt,
    treatmentDays: int.tryParse(duration.text),
    paused: paused,
    archived: archived,
  );

  void go(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      step = value;
      error = null;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Future<void> advance() async {
    if (saving || picking) return;
    if (!(form.currentState?.validate() ?? true)) return;
    if (step > 0) {
      try {
        medicine.validate();
      } on FormatException catch (e) {
        setState(() => error = e.message);
        return;
      }
    }
    if (step < 3) {
      go(step + 1);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final app = ref.read(appProvider);
    await app.saveMedicine(medicine);
    if (!mounted) return;
    if (app.error != null) {
      setState(() {
        saving = false;
        error = app.error;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${name.text} · ${tr(context, 'Saved on this device')}'),
      ),
    );
    context.go('/home');
  }

  Future<void> pickPhoto() async {
    setState(() {
      picking = true;
      error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 75,
        requestFullMetadata: false,
      );
      if (file != null) {
        if (await file.length() > 512000) {
          throw const FormatException('Choose a photo smaller than 500 KB.');
        }
        final bytes = await file.readAsBytes();
        // Store bounded image bytes with the existing JSON record, never a temporary picker path.
        if (mounted) setState(() => photo = base64Encode(bytes));
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Could not open this photo. Please try another image.',
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> pickTime([int? old]) async {
    final t = old ?? (times.isEmpty ? 480 : times.last);
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: t ~/ 60, minute: t % 60),
    );
    if (value == null || !mounted) return;
    final minute = value.hour * 60 + value.minute;
    if (minute != old && times.contains(minute)) {
      setState(() => error = 'This reminder time is already added.');
      return;
    }
    setState(() {
      if (old != null) times.remove(old);
      times.add(minute);
      times.sort();
      error = null;
    });
  }

  Future<DateTime?> pickDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  void applyDuration() {
    if (duration.text.trim().isEmpty) {
      end = null;
      return;
    }
    final value = int.tryParse(duration.text);
    if (value != null && value > 0 && value <= 3650) {
      end = DateTime(start.year, start.month, start.day + value - 1);
    }
  }

  String timeText(int t) =>
      TimeOfDay(hour: t ~/ 60, minute: t % 60).format(context);
  String get doseHint => switch (type) {
    'Tablet' => 'Number of tablets, as prescribed',
    'Capsule' => 'Number of capsules, as prescribed',
    'Syrup' || 'Liquid' => 'Amount in mL, as prescribed',
    'Injection' => 'Amount and unit from your prescription',
    'Drops' => 'Number of drops and site, as prescribed',
    'Inhaler' => 'Number of puffs, as prescribed',
    'Cream' => 'Amount and application site, as prescribed',
    _ => 'Enter the prescribed dosage',
  };

  Widget field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool required = false,
    int lines = 1,
    int max = 100,
    TextInputType? keyboard,
    String? Function(String?)? validate,
    ValueChanged<String>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(label),
      controller: controller,
      maxLines: lines,
      maxLength: max,
      keyboardType: keyboard,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: tr(context, label),
        hintText: hint == null ? null : tr(context, hint),
        counterText: '',
        alignLabelWithHint: lines > 1,
      ),
      validator:
          validate ??
          (required
              ? (v) => v == null || v.trim().isEmpty
                    ? tr(
                        context,
                        label == 'Medicine name'
                            ? 'Enter a medicine name'
                            : 'Enter the prescribed dosage',
                      )
                    : null
              : null),
    ),
  );

  Widget dropdown(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: tr(context, label)),
      items: {...values, value}
          .map((v) => DropdownMenuItem(value: v, child: Text(tr(context, v))))
          .toList(),
      onChanged: (v) {
        if (v != null) changed(v);
      },
    ),
  );

  Widget section(IconData icon, String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Card(
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark
          ? null
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: purple.withValues(alpha: .08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr(context, title),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    ),
  );

  Widget identity() => Row(
    children: [
      MedicineAvatar(photo: photo, color: color, size: 68),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.text.isEmpty ? tr(context, 'Your medicine') : name.text,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            Text(tr(context, type)),
            if (strength.text.isNotEmpty) Text(strength.text),
          ],
        ),
      ),
    ],
  );

  List<Widget> information() => [
    section(Icons.medication_outlined, 'Medicine Information', [
      field('Medicine name', name, required: true),
      dropdown('Type', type, types, (v) => setState(() => type = v)),
      field(
        'Strength (optional)',
        strength,
        hint: ['Syrup', 'Liquid', 'Drops'].contains(type)
            ? 'Concentration from label (mg/mL or %)'
            : type == 'Cream'
            ? 'Strength from label (%)'
            : 'Strength and unit from label (mg, mcg, IU)',
      ),
      field('Category (optional)', category),
    ]),
    section(Icons.palette_outlined, 'Appearance (optional)', [
      identity(),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: picking ? null : pickPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(tr(context, picking ? 'Loading…' : 'Choose photo')),
          ),
          if (photo.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => photo = ''),
              child: Text(tr(context, 'Remove photo')),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
          colors.length,
          (i) => Semantics(
            selected: color == colors[i],
            child: IconButton(
              tooltip: tr(
                context,
                ['Purple', 'Blue', 'Green', 'Gold', 'Pink'][i],
              ),
              onPressed: () => setState(() => color = colors[i]),
              style: IconButton.styleFrom(
                backgroundColor: Color(colors[i]),
                minimumSize: const Size(48, 48),
              ),
              icon: Icon(
                color == colors[i] ? Icons.check : Icons.circle_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ]),
  ];

  List<Widget> timing() => [
    section(Icons.medication_rounded, 'Dose per time', [
      field('Dosage', dosage, hint: doseHint, required: true),
      Text(
        tr(
          context,
          'Use your prescription or medicine label. Daryeel does not recommend a dose.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ]),
    section(Icons.event_repeat, 'Frequency', [
      dropdown(
        'Frequency',
        frequency,
        ['Daily', 'Specific weekdays', 'Every N days'],
        (v) => setState(() {
          frequency = v;
        }),
      ),
      if (frequency == 'Every N days')
        field(
          'Interval in days',
          interval,
          keyboard: TextInputType.number,
          validate: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n < 1 || n > 365
                ? tr(context, 'Enter an interval from 1 to 365 days.')
                : null;
          },
        ),
      if (frequency == 'Specific weekdays')
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            7,
            (i) => FilterChip(
              label: Text(dateLabel(context, DateTime(2026, 10, 19 + i), 'EE')),
              selected: days.contains(i + 1),
              onSelected: (v) =>
                  setState(() => v ? days.add(i + 1) : days.remove(i + 1)),
            ),
          ),
        ),
      if (frequency == 'Every N days')
        Text(tr(context, 'Intervals are counted from the start date.')),
    ]),
    section(Icons.access_time_rounded, 'Reminder times', [
      ...times.map(
        (t) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule, color: purple),
          title: Text(
            timeText(t),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          onTap: () => pickTime(t),
          trailing: IconButton(
            tooltip: tr(context, 'Remove time'),
            onPressed: () => setState(() => times.remove(t)),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ),
      OutlinedButton.icon(
        onPressed: times.length >= 12 ? null : () => pickTime(),
        icon: const Icon(Icons.add),
        label: Text(tr(context, 'Add time')),
      ),
    ]),
    if (!['Cream', 'Drops', 'Inhaler', 'Injection'].contains(type))
      section(Icons.restaurant_outlined, 'Food instructions', [
        dropdown('Food instructions', food, [
          'No preference',
          'Before food',
          'With food',
          'After food',
        ], (v) => setState(() => food = v)),
      ]),
  ];

  List<Widget> details() => [
    section(Icons.date_range_outlined, 'Treatment dates', [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(tr(context, 'Start date')),
        subtitle: Text(dateLabel(context, start)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final d = await pickDate(start);
          if (d != null && mounted) {
            setState(() {
              start = d;
              if (duration.text.trim().isNotEmpty) applyDuration();
            });
          }
        },
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(tr(context, 'End date')),
        subtitle: Text(
          end == null ? tr(context, 'No end date') : dateLabel(context, end!),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final d = await pickDate(end ?? start);
          if (d != null && mounted) {
            setState(() {
              end = d;
              duration.clear();
            });
          }
        },
      ),
      if (end != null)
        TextButton(
          onPressed: () => setState(() {
            end = null;
            duration.clear();
          }),
          child: Text(tr(context, 'No end date')),
        ),
      const SizedBox(height: 12),
      field(
        'Treatment duration (days)',
        duration,
        keyboard: TextInputType.number,
        validate: (v) {
          if (v == null || v.isEmpty) return null;
          final n = int.tryParse(v);
          return n == null || n < 1 || n > 3650
              ? tr(context, 'Enter a duration from 1 to 3650 days.')
              : null;
        },
        onChanged: (_) => setState(applyDuration),
      ),
    ]),
    section(Icons.notifications_active_outlined, 'Notification preferences', [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(tr(context, 'Enable reminders')),
        value: reminders,
        onChanged: (v) => setState(() => reminders = v),
      ),
      if (reminders)
        DropdownButtonFormField<int>(
          initialValue: repeats,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: tr(context, 'Repeat every 10 minutes'),
          ),
          items: List.generate(
            4,
            (i) => DropdownMenuItem(
              value: i,
              child: Text(
                i == 0
                    ? tr(context, 'No repeats')
                    : trf(context, 'repeatCount', {'count': '$i'}),
              ),
            ),
          ),
          onChanged: (v) => setState(() => repeats = v!),
        ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(tr(context, 'Refill reminder')),
        subtitle: Text(tr(context, 'Choose when to be reminded to refill.')),
        value: refillAt != null,
        onChanged: (v) async {
          if (!v) {
            setState(() => refillAt = null);
            return;
          }
          await chooseRefill();
        },
      ),
      if (refillAt != null)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            '${dateLabel(context, refillAt!)} · ${TimeOfDay.fromDateTime(refillAt!).format(context)}',
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: chooseRefill,
        ),
      Text(
        tr(
          context,
          'Reminders depend on device permissions and battery settings. Repeated reminders stop when you record or skip a dose. Open Daryeel at least monthly to refresh upcoming reminders.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      TextButton(
        onPressed: () => context.push('/settings'),
        child: Text(tr(context, 'Open settings')),
      ),
    ]),
    section(Icons.notes_outlined, 'Instructions & notes', [
      field(
        'Instructions',
        instructions,
        hint: 'Instructions from your healthcare professional',
        lines: 3,
        max: 1000,
      ),
      field('Notes (optional)', notes, lines: 3, max: 1000),
    ]),
  ];

  Future<void> chooseRefill() async {
    final d = await pickDate(refillAt ?? DateTime.now());
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: refillAt == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(refillAt!),
    );
    if (t == null || !mounted) return;
    final value = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    if (!value.isAfter(DateTime.now())) {
      setState(() => error = 'Choose a future refill reminder.');
      return;
    }
    setState(() {
      refillAt = value;
      error = null;
    });
  }

  Widget summary(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final texts = <Widget>[
          Text(
            tr(context, label),
            style: const TextStyle(color: purple, fontWeight: FontWeight.w600),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ];
        if (constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(16) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [texts.first, const SizedBox(height: 4), texts.last],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: texts.first),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: texts.last,
              ),
            ),
          ],
        );
      },
    ),
  );
  Widget editButton(int target) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: TextButton.icon(
      onPressed: () => go(target),
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: Text(tr(context, 'Edit')),
    ),
  );
  List<Widget> review() => [
    section(Icons.medication_outlined, 'Medicine Information', [
      identity(),
      if (category.text.isNotEmpty)
        summary('Category (optional)', category.text),
      editButton(0),
    ]),
    section(Icons.schedule, 'Dosage & Timing', [
      summary('Dosage', dosage.text),
      summary(
        'Frequency',
        frequency == 'Every N days'
            ? '${tr(context, frequency)}: ${interval.text}'
            : tr(context, frequency),
      ),
      summary('Reminder times', times.map(timeText).join(' · ')),
      if (frequency == 'Specific weekdays')
        summary(
          'Specific weekdays',
          (days.toList()..sort())
              .map((d) => dateLabel(context, DateTime(2026, 10, 18 + d), 'EEE'))
              .join(' · '),
        ),
      if (food != 'No preference')
        summary('Food instructions', tr(context, food)),
      editButton(1),
    ]),
    section(Icons.fact_check_outlined, 'Additional Details', [
      summary('Start date', dateLabel(context, start)),
      summary(
        'End date',
        end == null ? tr(context, 'No end date') : dateLabel(context, end!),
      ),
      if (duration.text.isNotEmpty)
        summary('Treatment duration (days)', duration.text),
      summary('Enable reminders', tr(context, reminders ? 'On' : 'Off')),
      if (reminders)
        summary(
          'Repeat every 10 minutes',
          repeats == 0
              ? tr(context, 'No repeats')
              : trf(context, 'repeatCount', {'count': '$repeats'}),
        ),
      summary(
        'Refill reminder',
        refillAt == null
            ? tr(context, 'Off')
            : '${dateLabel(context, refillAt!)} · ${TimeOfDay.fromDateTime(refillAt!).format(context)}',
      ),
      if (instructions.text.isNotEmpty)
        summary('Instructions', instructions.text),
      if (notes.text.isNotEmpty) summary('Notes (optional)', notes.text),
      editButton(2),
    ]),
  ];

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving && step == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !saving && step > 0) go(step - 1);
    },
    child: Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : const Color(0xFFFCFBFF),
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          tooltip: tr(context, 'Back'),
          onPressed: saving
              ? null
              : () {
                  if (step > 0) {
                    go(step - 1);
                  } else if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          tr(context, widget.id == null ? 'Add medicine' : 'Edit medicine'),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      tr(context, error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  if (step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving ? null : () => go(step - 1),
                        child: Text(tr(context, 'Back')),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: CareButton(
                      onPressed: saving || picking ? null : advance,
                      child: Text(
                        tr(
                          context,
                          saving
                              ? 'Saving…'
                              : step == 3
                              ? 'Save'
                              : 'Continue',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: Row(
                children: List.generate(7, (i) {
                  if (i.isOdd) {
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: i ~/ 2 < step ? purple : lavender,
                      ),
                    );
                  }
                  final n = i ~/ 2;
                  return Semantics(
                    label: '${tr(context, titles[n])}, ${n + 1} / 4',
                    selected: n == step,
                    child: AnimatedContainer(
                      duration: motionDuration(context, 220),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: n <= step ? null : lavender,
                        gradient: n <= step
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF9D55FF), Color(0xFF5D25D6)],
                              )
                            : null,
                        boxShadow: n == step
                            ? [
                                BoxShadow(
                                  color: purple.withValues(alpha: .2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          '${n + 1}',
                          key: ValueKey('step-number-$step-$n'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: n <= step ? Colors.white : ink,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: AbsorbPointer(
                absorbing: saving,
                child: SingleChildScrollView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedSwitcher(
                              duration: motionDuration(context, 220),
                              child: Text(
                                tr(context, titles[step]),
                                key: ValueKey(step),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr(
                                context,
                                [
                                  'Add the details from your medicine label.',
                                  'Set how much and when to take it.',
                                  'Add extra information (optional).',
                                  'Check your medicine details before saving.',
                                ][step],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            SoftEntrance(
                              key: ValueKey('step-body-$step'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: switch (step) {
                                  0 => information(),
                                  1 => timing(),
                                  2 => details(),
                                  _ => review(),
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
