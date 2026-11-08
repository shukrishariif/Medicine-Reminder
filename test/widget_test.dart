import 'local_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:daryeel/main.dart';
import 'package:daryeel/data/repository.dart';
import 'package:daryeel/services/app_controller.dart';
import 'package:daryeel/services/reminders.dart';

void main() {
  testWidgets('onboarding, guest dashboard and bottom navigation', (
    tester,
  ) async {
    late AppController app;
    await tester.runAsync(() async {
      final db = await databaseFactoryMemory.openDatabase('widget');
      app = LocalTestController(LocalRepository(db), ReminderService());
      await app.initialize();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => app)],
        child: const DaryeelApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daryeel'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Next'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Next'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Amina');
    await tester.scrollUntilVisible(
      find.text('Get Started'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Get Started'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Amina'), findsOneWidget);
    expect(find.text("Today's Progress"), findsOneWidget);
    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('No doses scheduled'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('No doses scheduled'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => app.repository.db.close());
  });
  testWidgets('dashboard tolerates narrow screen, large text and Arabic RTL', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    late AppController app;
    await tester.runAsync(() async {
      final db = await databaseFactoryMemory.openDatabase('rtl');
      final repo = LocalRepository(db);
      await repo.saveSettings({
        'onboarded': true,
        'language': 'ar',
        'name': 'أمينة',
      });
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
    expect(find.text('أمينة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('أمينة'))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => app.setSettings({'language': 'so'}));
    await tester.pumpAndSettle();
    expect(find.text('Hoyga'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => app.repository.db.close());
  });
}
