import 'local_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:daryeel/main.dart';
import 'package:daryeel/core/premium.dart';
import 'package:daryeel/features/navigation.dart';
import 'package:daryeel/data/models.dart';
import 'package:daryeel/data/repository.dart';
import 'package:daryeel/services/app_controller.dart';
import 'package:daryeel/services/reminders.dart';

Future<AppController> mountApp(WidgetTester tester, String name) async {
  late AppController app;
  await tester.runAsync(() async {
    final db = await databaseFactoryMemory.openDatabase(name);
    final repo = LocalRepository(db);
    await repo.saveSettings({'onboarded': true, 'name': 'Amina'});
    app = LocalTestController(repo, ReminderService());
    await app.initialize();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appProvider.overrideWith((ref) => app)],
      child: const DaryeelApp(),
    ),
  );
  await tester.pumpAndSettle();
  return app;
}

Future<void> tapAction(WidgetTester tester, String label) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final button = find.widgetWithText(FilledButton, label);
  await tester.scrollUntilVisible(
    button,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(button);
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'circular add action is centered and opens medicine editor from every tab',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = await mountApp(tester, 'centered-add');
      final router = GoRouter.of(tester.element(find.text('Amina')));
      for (final path in ['/home', '/schedule', '/history', '/profile']) {
        router.go(path);
        await tester.pumpAndSettle();
        final rect = tester.getRect(find.byKey(const ValueKey('add-medicine')));
        expect(rect.width, rect.height);
        expect(rect.center.dx, closeTo(195, 1));
        expect(
          rect.center.dy,
          lessThan(tester.getRect(find.byType(DaryeelNavigation)).top + 5),
        );
        expect(
          find.descendant(
            of: find.byType(AddMedicineButton),
            matching: find.byType(Text),
          ),
          findsNothing,
        );
        await tester.tap(find.byTooltip('Add medicine'));
        await tester.pumpAndSettle();
        expect(find.text('Medicine name'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => app.repository.db.close());
    },
  );

  testWidgets('onboarding skip persists completion and is not shown again', (
    tester,
  ) async {
    final app = await mountApp(tester, 'skip-intro');
    final router = GoRouter.of(tester.element(find.text('Amina')));
    await tester.runAsync(() => app.setSettings({'onboarded': false}));
    router.go('/onboarding');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Page 2'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Page 2'));
    await tester.pumpAndSettle();
    expect(find.text('Smart Reminders'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Skip'));
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pumpAndSettle();
    expect(app.onboarded, isTrue);
    expect(find.text('Amina'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    final restarted = LocalTestController(app.repository, ReminderService());
    await tester.runAsync(restarted.initialize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => restarted)],
        child: const DaryeelApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Take Care Today for a Healthier Tomorrow'), findsNothing);
    expect(find.text('Amina'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => app.repository.db.close());
  });
  testWidgets(
    'premium medicine UI preserves create, edit, snooze, completion and deletion',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = await mountApp(tester, 'premium-actions');
      final router = GoRouter.of(tester.element(find.text('Amina')));
      await tester.tap(find.byTooltip('Add medicine'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'My vitamin');
      await tapAction(tester, 'Continue');
      await tester.enterText(find.byKey(const ValueKey('Dosage')), '1 tablet');
      FocusManager.instance.primaryFocus?.unfocus();
      for (var step = 0; step < 2; step++) {
        await tapAction(tester, 'Continue');
      }
      await tapAction(tester, 'Save');
      expect(app.medicines.single.name, 'My vitamin');
      final id = app.medicines.single.id;
      router.go('/edit/$id');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Updated vitamin',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      for (var step = 0; step < 3; step++) {
        await tapAction(tester, 'Continue');
      }
      await tapAction(tester, 'Save');
      expect(app.medicines.single.name, 'Updated vitamin');
      final dose = app.today.single;
      router.go('/alarm/${Uri.encodeComponent(dose.id)}');
      await tester.pumpAndSettle();
      final snooze = find.byTooltip('Snooze');
      await tester.scrollUntilVisible(
        snooze,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(snooze));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('10 min'));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      expect(app.records[dose.id]!.recordedStatus, DoseStatus.snoozed);
      await tapAction(tester, 'Take Now');
      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        await tester.runAsync(() async {
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await Future<void>.delayed(const Duration(milliseconds: 80));
        });
        await tester.pumpAndSettle();
      }
      expect(app.records[dose.id]!.recordedStatus, DoseStatus.taken);
      expect(app.records[dose.id]!.completedAt, isNotNull);
      expect(find.widgetWithText(FilledButton, 'Take Now'), findsNothing);
      router.go('/medicine/$id');
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        tester
            .widget<PopupMenuButton<String>>(
              find.byType(PopupMenuButton<String>),
            )
            .onSelected!('delete');
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        await app.settleAccount();
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() => app.settleAccount());
      await tester.pumpAndSettle();
      expect(app.medicines, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => app.repository.db.close());
    },
  );

  testWidgets(
    'all primary screens support narrow large-text RTL and dark mode',
    (tester) async {
      final reportError = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        reportError?.call(details);
      };
      addTearDown(() => FlutterError.onError = reportError);
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final app = await mountApp(tester, 'premium-accessibility');
      final router = GoRouter.of(tester.element(find.text('Amina')));
      await tester.runAsync(
        () => app.saveMedicine(
          Medicine(
            id: newId(),
            name: 'A medicine with a deliberately long name',
            dosage: 'One tablet with a full glass of water',
            instructions: 'Schedule',
            start: dayOnly(DateTime.now()),
            times: [480],
          ),
        ),
      );
      final id = app.medicines.single.id;
      final dose = app.today.single.id;
      for (final language in ['en', 'so', 'ar']) {
        await tester.runAsync(
          () =>
              app.setSettings({'language': language, 'dark': language == 'ar'}),
        );
        for (final path in [
          '/home',
          '/schedule',
          '/history',
          '/profile',
          '/settings',
          '/medicine/$id',
          '/edit/$id',
          '/alarm/${Uri.encodeComponent(dose)}',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$language $path at top',
          );
          for (var i = 0; i < 5; i++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -400),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$language $path scroll $i',
            );
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => app.repository.db.close());
    },
  );

  testWidgets(
    'press feedback honors reduced motion and retains button action',
    (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: CareButton(
                onPressed: () => presses++,
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Action'));
      await tester.pumpAndSettle();
      expect(presses, 1);
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
        Duration.zero,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );
}
