import 'package:uuid/uuid.dart';

typedef Json = Map<String, dynamic>;
String newId() => const Uuid().v4();
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

enum DoseStatus { pending, due, taken, skipped, missed, snoozed }

class Medicine {
  final String id, name, dosage, type, instructions;
  final List<int> times, weekdays;
  final DateTime start;
  final DateTime? end;
  final bool paused, archived, reminders;
  final int repeats;
  final String strength, category, notes, food, photo;
  final int color, intervalDays;
  final DateTime? refillAt;
  final int? treatmentDays;
  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    this.type = 'Tablet',
    this.instructions = '',
    required this.times,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    required this.start,
    this.end,
    this.paused = false,
    this.archived = false,
    this.reminders = true,
    this.repeats = 0,
    this.strength = '',
    this.category = '',
    this.notes = '',
    this.food = 'No preference',
    this.photo = '',
    this.color = 0xFF6240D7,
    this.intervalDays = 1,
    this.refillAt,
    this.treatmentDays,
  });
  factory Medicine.fromJson(Json j) => Medicine(
    id: j['id'],
    name: j['name'],
    dosage: j['dosage'],
    type: j['type'] ?? 'Tablet',
    instructions: j['instructions'] ?? '',
    times: List<int>.from(j['times']),
    weekdays: List<int>.from(j['weekdays']),
    start: DateTime.parse(j['start']),
    end: j['end'] == null ? null : DateTime.parse(j['end']),
    paused: j['paused'] ?? false,
    archived: j['archived'] ?? false,
    reminders: j['reminders'] ?? true,
    repeats: j['repeats'] ?? 0,
    strength: j['strength'] ?? '',
    category: j['category'] ?? '',
    notes: j['notes'] ?? '',
    food: j['food'] ?? 'No preference',
    photo: j['photo'] ?? '',
    color: j['color'] ?? 0xFF6240D7,
    intervalDays: j['intervalDays'] ?? 1,
    treatmentDays: j['treatmentDays'],
    refillAt: j['refillAt'] == null
        ? null
        : DateTime.parse(j['refillAt']).toLocal(),
  );
  Json toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'type': type,
    'instructions': instructions,
    'times': times,
    'weekdays': weekdays,
    'start': dayKey(start),
    'end': end == null ? null : dayKey(end!),
    'paused': paused,
    'archived': archived,
    'reminders': reminders,
    'repeats': repeats,
    'strength': strength,
    'category': category,
    'notes': notes,
    'food': food,
    'photo': photo,
    'color': color,
    'intervalDays': intervalDays,
    'treatmentDays': treatmentDays,
    'refillAt': refillAt?.toUtc().toIso8601String(),
  };
  Medicine change(Json updates) => Medicine.fromJson({...toJson(), ...updates});
  void validate() {
    if (treatmentDays != null &&
        (treatmentDays! < 1 || treatmentDays! > 3650)) {
      throw const FormatException('Enter a duration from 1 to 3650 days.');
    }
    if (intervalDays < 1 || intervalDays > 365) {
      throw const FormatException('Enter an interval from 1 to 365 days.');
    }
    if (name.trim().isEmpty || dosage.trim().isEmpty) {
      throw const FormatException('Enter a medicine name and dosage.');
    }
    if (times.isEmpty ||
        times.length > 12 ||
        times.any((t) => t < 0 || t >= 1440) ||
        times.toSet().length != times.length) {
      throw const FormatException('Choose 1–12 different reminder times.');
    }
    if (weekdays.isEmpty || weekdays.any((d) => d < 1 || d > 7)) {
      throw const FormatException('Choose at least one weekday.');
    }
    if (end != null && dayOnly(end!).isBefore(dayOnly(start))) {
      throw const FormatException('End date must follow the start date.');
    }
    if (repeats < 0 || repeats > 3) {
      throw const FormatException('Repeat reminders must be between 0 and 3.');
    }
  }
}

class Dose {
  final String id, medicineId, name, dosage;
  final DateTime scheduled;
  final DoseStatus recordedStatus;
  final DateTime? completedAt, snoozedUntil;
  const Dose({
    required this.id,
    required this.medicineId,
    required this.name,
    required this.dosage,
    required this.scheduled,
    this.recordedStatus = DoseStatus.pending,
    this.completedAt,
    this.snoozedUntil,
  });
  bool get resolved =>
      recordedStatus == DoseStatus.taken ||
      recordedStatus == DoseStatus.skipped;
  DoseStatus statusAt(DateTime now) {
    if (resolved) {
      return recordedStatus;
    }
    final due = snoozedUntil ?? scheduled;
    if (now.isBefore(due)) {
      return snoozedUntil == null ? DoseStatus.pending : DoseStatus.snoozed;
    }
    return now.difference(due) >= const Duration(hours: 2)
        ? DoseStatus.missed
        : DoseStatus.due;
  }

  factory Dose.fromJson(Json j) => Dose(
    id: j['id'],
    medicineId: j['medicineId'],
    name: j['name'],
    dosage: j['dosage'],
    scheduled: DateTime.parse(j['scheduled']).toLocal(),
    recordedStatus: DoseStatus.values.byName(j['status']),
    completedAt: j['completedAt'] == null
        ? null
        : DateTime.parse(j['completedAt']).toLocal(),
    snoozedUntil: j['snoozedUntil'] == null
        ? null
        : DateTime.parse(j['snoozedUntil']).toLocal(),
  );
  Json toJson() => {
    'id': id,
    'medicineId': medicineId,
    'name': name,
    'dosage': dosage,
    'scheduled': scheduled.toUtc().toIso8601String(),
    'status': recordedStatus.name,
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'snoozedUntil': snoozedUntil?.toUtc().toIso8601String(),
  };
  Dose change(Json updates) => Dose.fromJson({...toJson(), ...updates});
}

/// IDs use local calendar date and wall-clock minute, never list position.
/// Date construction (rather than adding 24 hours) handles DST calendar days.
List<Dose> generateDoses(
  Iterable<Medicine> medicines,
  DateTime from,
  DateTime through,
) {
  final doses = <Dose>[];
  for (final m in medicines) {
    if (m.paused || m.archived) {
      continue;
    }
    for (
      var day = dayOnly(from);
      !day.isAfter(dayOnly(through));
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      if (day.isBefore(dayOnly(m.start)) ||
          (m.end != null && day.isAfter(dayOnly(m.end!))) ||
          !m.weekdays.contains(day.weekday)) {
        continue;
      }
      // Calendar-day arithmetic remains stable through daylight-saving changes.
      final elapsed = DateTime.utc(day.year, day.month, day.day)
          .difference(DateTime.utc(m.start.year, m.start.month, m.start.day))
          .inDays;
      if (elapsed % m.intervalDays != 0) continue;
      for (final minute in m.times.toSet()) {
        doses.add(
          Dose(
            id: '${m.id}_${dayKey(day)}_$minute',
            medicineId: m.id,
            name: m.name,
            dosage: m.dosage,
            scheduled: DateTime(
              day.year,
              day.month,
              day.day,
              minute ~/ 60,
              minute % 60,
            ),
          ),
        );
      }
    }
  }
  return doses..sort((a, b) => a.scheduled.compareTo(b.scheduled));
}
