import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:daryeel/data/models.dart';
import 'package:daryeel/core/strings.dart';
import 'premium_flows_test.dart' show mountApp, tapAction;

Future<void> enter(WidgetTester tester, String key, String value) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  test('legacy records and optional medicine metadata survive round trips', () {
    final old = Medicine(
      id: 'old',
      name: 'Existing',
      dosage: 'Label dose',
      times: [480],
      start: DateTime(2026, 1, 1),
    ).toJson();
    for (final key in [
      'strength',
      'category',
      'notes',
      'food',
      'photo',
      'color',
      'intervalDays',
      'refillAt',
    ]) {
      old.remove(key);
    }
    final legacy = Medicine.fromJson(old);
    expect(legacy.intervalDays, 1);
    expect(legacy.refillAt, isNull);
    expect(legacy.dosage, 'Label dose');
    final updated = legacy.change({
      'strength': 'Label strength',
      'category': 'Personal category',
      'notes': 'My notes',
      'food': 'After food',
      'color': 0xFF2575CA,
      'photo': 'cGhvdG8=',
      'refillAt': DateTime(2027, 2, 1, 10).toUtc().toIso8601String(),
    });
    expect(
      Medicine.fromJson(updated.toJson()).change({'paused': true}).toJson(),
      {...updated.toJson(), 'paused': true},
    );
  });

  test(
    'interval schedules anchor to start across month and year boundaries',
    () {
      final m = Medicine(
        id: 'interval',
        name: 'User medicine',
        dosage: 'User dose',
        start: DateTime(2026, 12, 30),
        end: DateTime(2027, 1, 5),
        intervalDays: 2,
        times: [480, 1200],
      );
      final doses = generateDoses(
        [m],
        DateTime(2026, 12, 29),
        DateTime(2027, 1, 9),
      );
      expect(doses.map((d) => dayKey(d.scheduled)).toSet(), {
        '2026-12-30',
        '2027-01-01',
        '2027-01-03',
        '2027-01-05',
      });
      expect(doses.length, 8);
      expect(
        () => m.change({'intervalDays': 0}).validate(),
        throwsFormatException,
      );
      expect(
        () => m.change({
          'times': [480, 480],
        }).validate(),
        throwsFormatException,
      );
      expect(
        () => m.change({'weekdays': []}).validate(),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'four steps validate, retain edits, calculate duration and save one record',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = await mountApp(tester, 'medicine-four-steps');
      final router = GoRouter.of(tester.element(find.text('Amina')));
      router.go('/medicine/new');
      await tester.pumpAndSettle();
      await tapAction(tester, 'Continue');
      expect(find.text('Enter a medicine name'), findsOneWidget);
      await enter(tester, 'Medicine name', 'Prescription medicine');
      await enter(tester, 'Strength (optional)', 'Label strength');
      await enter(tester, 'Category (optional)', 'My category');
      await tapAction(tester, 'Continue');
      await tapAction(tester, 'Continue');
      expect(find.text('Enter the prescribed dosage'), findsOneWidget);
      await enter(tester, 'Dosage', 'Amount from my label');
      final frequency = find.byKey(const ValueKey('Frequency:Daily'));
      await tester.ensureVisible(frequency);
      await tester.pumpAndSettle();
      await tester.tap(frequency);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Every N days').last);
      await tester.pumpAndSettle();
      await enter(tester, 'Interval in days', '0');
      await tapAction(tester, 'Continue');
      expect(find.text('Enter an interval from 1 to 365 days.'), findsWidgets);
      await enter(tester, 'Interval in days', '3');
      await tapAction(tester, 'Continue');
      await enter(tester, 'Treatment duration (days)', '10');
      await enter(tester, 'Treatment duration (days)', '');
      expect(find.text('No end date'), findsOneWidget);
      await enter(tester, 'Treatment duration (days)', '10');
      await enter(tester, 'Instructions', 'Instructions entered by the user');
      await enter(tester, 'Notes (optional)', 'Personal note');
      await tapAction(tester, 'Continue');
      expect(find.text('Prescription medicine'), findsOneWidget);
      expect(find.text('Label strength'), findsOneWidget);
      final edits = find.text('Edit');
      await tester.ensureVisible(edits.first);
      await tester.pumpAndSettle();
      await tester.tap(edits.first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('Medicine name')))
            .controller!
            .text,
        'Prescription medicine',
      );
      await enter(tester, 'Medicine name', 'Edited prescription');
      for (var i = 0; i < 3; i++) {
        await tapAction(tester, 'Continue');
      }
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        // Two immediate taps must not create two records.
        await tester.tap(save);
        await tester.tap(save);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      final saved = app.medicines.single;
      expect(saved.name, 'Edited prescription');
      expect(saved.strength, 'Label strength');
      expect(saved.intervalDays, 3);
      expect(saved.notes, 'Personal note');
      expect(
        saved.end,
        DateTime(saved.start.year, saved.start.month, saved.start.day + 9),
      );
      expect(app.doses(saved.start, saved.end!).length, 4);
      final rows = await tester.runAsync(() => app.repository.all('guest'));
      expect(rows!.where((r) => r['kind'] == 'medicine').length, 1);
      router.go('/edit/${saved.id}');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('Strength (optional)')),
            )
            .controller!
            .text,
        'Label strength',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => app.repository.db.close());
    },
  );

  testWidgets(
    'frequency changes retain weekday choices without restricting daily doses',
    (tester) async {
      final app = await mountApp(tester, 'retain-weekdays');
      final router = GoRouter.of(tester.element(find.text('Amina')));
      await tester.runAsync(
        () => app.saveMedicine(
          Medicine(
            id: 'weekly',
            name: 'Label medicine',
            dosage: 'Label dose',
            times: [480],
            weekdays: [1, 3],
            start: DateTime.now(),
          ),
        ),
      );
      router.go('/edit/weekly');
      await tester.pumpAndSettle();
      await tapAction(tester, 'Continue');
      Future<void> selectFrequency(String current, String next) async {
        final field = find.byKey(ValueKey('Frequency:$current'));
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text(next).last);
        await tester.pumpAndSettle();
      }

      await selectFrequency('Specific weekdays', 'Daily');
      await selectFrequency('Daily', 'Specific weekdays');
      final chips = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .toList();
      expect(chips.map((c) => c.selected).toList(), [
        true,
        false,
        true,
        false,
        false,
        false,
        false,
      ]);
      await selectFrequency('Specific weekdays', 'Daily');
      await tapAction(tester, 'Continue');
      await tapAction(tester, 'Continue');
      await tapAction(tester, 'Save');
      expect(app.medicines.single.weekdays, [1, 2, 3, 4, 5, 6, 7]);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => app.repository.db.close());
    },
  );

  testWidgets('all setup steps fit large text in English, Somali and Arabic', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final app = await mountApp(tester, 'medicine-step-locales');
    final router = GoRouter.of(tester.element(find.text('Amina')));
    await tester.runAsync(
      () => app.saveMedicine(
        Medicine(
          id: 'localized',
          name: 'User medicine',
          dosage: 'User dosage',
          start: DateTime.now(),
          times: [480, 1200],
        ),
      ),
    );
    for (final language in ['en', 'so', 'ar']) {
      await tester.runAsync(() => app.setSettings({'language': language}));
      router.go('/home');
      await tester.pumpAndSettle();
      router.go('/edit/localized');
      await tester.pumpAndSettle();
      for (var step = 0; step < 3; step++) {
        await tapAction(tester, AppStrings(language)('Continue'));
        expect(tester.takeException(), isNull, reason: '$language step $step');
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => app.repository.db.close());
  });
}
