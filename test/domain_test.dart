import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:daryeel/data/models.dart';
import 'package:daryeel/data/repository.dart';
import 'package:daryeel/services/app_controller.dart';
import 'package:daryeel/services/reminders.dart';

class FakeReminders extends ReminderService {
  List<Dose> active = [];
  int reconciliations = 0;
  @override
  Future<void> reconcile(
    List<Dose> doses,
    List<Medicine> medicines,
    Json settings,
  ) async {
    reconciliations++;
    active = doses
        .where(
          (d) =>
              !d.resolved &&
              medicines.any(
                (m) =>
                    m.id == d.medicineId &&
                    !m.paused &&
                    !m.archived &&
                    m.reminders,
              ),
        )
        .toList();
  }
}

Medicine example({
  DateTime? start,
  List<int> times = const [480, 1200],
  List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
}) => Medicine(
  id: 'medicine-1',
  name: 'Example medicine',
  dosage: '1 tablet',
  times: times,
  weekdays: weekdays,
  start: start ?? DateTime(2026, 10, 1),
);
void main() {
  test(
    'inclusive dates, weekday selection, multiple times, deterministic IDs',
    () {
      final m = example(weekdays: [1, 3]).change({'end': '2026-10-28'});
      final doses = generateDoses(
        [m],
        DateTime(2026, 10, 26),
        DateTime(2026, 11, 2),
      );
      expect(doses, hasLength(4));
      expect(doses.map((d) => d.id).toSet(), hasLength(4));
      expect(doses.first.id, 'medicine-1_2026-10-26_480');
      expect(
        generateDoses(
          [m],
          DateTime(2026, 10, 26),
          DateTime(2026, 11, 2),
        ).first.id,
        doses.first.id,
      );
      expect(
        generateDoses(
          [
            m.change({'paused': true}),
          ],
          DateTime(2026, 10, 26),
          DateTime(2026, 10, 27),
        ),
        isEmpty,
      );
    },
  );
  test('invalid schedules are rejected', () {
    expect(() => example(times: []).validate(), throwsFormatException);
    expect(() => example(times: [480, 480]).validate(), throwsFormatException);
    expect(() => example(weekdays: []).validate(), throwsFormatException);
    expect(
      () => example().change({'end': '2020-01-01'}).validate(),
      throwsFormatException,
    );
  });
  test('calendar generation crosses year and leap-day boundaries', () {
    final m = example(start: DateTime(2024, 1, 1), times: [0]);
    expect(
      generateDoses([m], DateTime(2024, 2, 28), DateTime(2024, 3, 1)),
      hasLength(3),
    );
    expect(
      generateDoses([m], DateTime(2026, 12, 31), DateTime(2027, 1, 1)),
      hasLength(2),
    );
  });
  test('dose status and actual completion survive UTC serialization', () {
    final at = DateTime(2026, 10, 26, 8);
    final d = Dose(
      id: 'd',
      medicineId: 'm',
      name: 'M',
      dosage: '1',
      scheduled: at,
    );
    expect(
      d.statusAt(at.subtract(const Duration(minutes: 1))),
      DoseStatus.pending,
    );
    expect(d.statusAt(at), DoseStatus.due);
    expect(d.statusAt(at.add(const Duration(hours: 2))), DoseStatus.missed);
    final taken = d.change({
      'status': 'taken',
      'completedAt': at.toUtc().toIso8601String(),
    });
    expect(Dose.fromJson(taken.toJson()).completedAt, at);
    expect(taken.statusAt(at.add(const Duration(days: 7))), DoseStatus.taken);
  });
  group('offline repository and controller', () {
    late LocalRepository repo;
    late AppController app;
    late FakeReminders reminders;
    setUp(() async {
      repo = LocalRepository(await databaseFactoryMemory.openDatabase(newId()));
      reminders = FakeReminders();
      app = AppController(repo, reminders);
      await app.initialize();
    });
    tearDown(() async {
      app.dispose();
      await repo.db.close();
    });
    test(
      'creation, completion, duplicate prevention, history, and reload',
      () async {
        final now = DateTime.now();
        await app.saveMedicine(
          example(start: dayOnly(now), times: [now.hour * 60 + now.minute]),
        );
        expect(app.medicines, hasLength(1));
        final d = app.today.first;
        await app.updateDose(d, DoseStatus.taken);
        final completed = app.records[d.id]!.completedAt;
        await app.updateDose(d, DoseStatus.taken);
        expect(
          app.today.where((d) => d.recordedStatus == DoseStatus.taken),
          hasLength(1),
        );
        expect(app.records[d.id]!.completedAt, completed);
        expect(reminders.active.where((r) => r.id == d.id), isEmpty);
        final second = AppController(repo, FakeReminders());
        await second.initialize();
        expect(second.today.first.recordedStatus, DoseStatus.taken);
        second.dispose();
      },
    );
    test(
      'snooze, edit, pause, delete reconcile reminders and retain history',
      () async {
        final now = DateTime.now();
        await app.saveMedicine(
          example(start: dayOnly(now), times: [now.hour * 60 + now.minute]),
        );
        final d = app.today.first;
        await app.updateDose(d, DoseStatus.snoozed, snoozeMinutes: 10);
        expect(app.records[d.id]!.statusAt(now), DoseStatus.snoozed);
        expect(
          app.records[d.id]!.snoozedUntil!.difference(DateTime.now()).inMinutes,
          inInclusiveRange(9, 10),
        );
        await app.saveMedicine(
          app.medicines.first.change({'name': 'Renamed', 'paused': true}),
        );
        expect(app.medicines.first.name, 'Renamed');
        expect(reminders.active, isEmpty);
        await app.deleteMedicine(app.medicines.first);
        expect(app.medicines, isEmpty);
        expect(app.records[d.id], isNotNull);
      },
    );
    test(
      'conflict merge preserves newer local changes; remote tombstones win by timestamp',
      () async {
        await repo.put('guest', 'medicine', 'm', {'id': 'm'});
        final local = (await repo.all('guest')).first;
        await repo.merge('guest', [
          {
            ...local,
            'data': {'id': 'm', 'name': 'Old'},
            'modified': '2000-01-01T00:00:00Z',
          },
        ]);
        expect((await repo.all('guest')).first['dirty'], true);
        await repo.merge('guest', [
          {...local, 'deleted': true, 'modified': '2099-01-01T00:00:00Z'},
        ]);
        expect((await repo.all('guest')).first['deleted'], true);
        expect((await repo.all('guest')).first['dirty'], false);
      },
    );
    test(
      'account partitions and guest migration do not leak records',
      () async {
        await repo.put('guest', 'medicine', 'm', {'id': 'm'});
        expect(await repo.all('user-a'), isEmpty);
        await repo.migrateGuest('user-a');
        expect(await repo.all('guest'), isEmpty);
        expect(await repo.all('user-a'), hasLength(1));
        expect(await repo.all('user-b'), isEmpty);
      },
    );
    test(
      'backup validation is atomic and successful restore is persistent',
      () async {
        await app.saveMedicine(example(start: dayOnly(DateTime.now())));
        final backup = await app.exportBackup();
        await repo.clearOwner('guest');
        await app.reload();
        expect(app.medicines, isEmpty);
        await app.restoreBackup(backup);
        expect(app.medicines, hasLength(1));
        await app.restoreBackup('{"version":1,"records":[{"kind":"invalid"}]}');
        expect(app.error, isNotNull);
        expect(app.medicines, hasLength(1));
      },
    );
  });
  test('notification IDs are stable and distinct', () {
    final a = ReminderService(), b = ReminderService();
    expect(a.idFor('one'), b.idFor('one'));
    expect(a.idFor('one'), isNot(a.idFor('two')));
  });
}
