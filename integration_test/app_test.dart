import '../test/local_controller.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:daryeel/main.dart';
import 'package:daryeel/data/models.dart';
import 'package:daryeel/data/repository.dart';
import 'package:daryeel/services/app_controller.dart';
import 'package:daryeel/services/reminders.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android persistence, medicine form, completion and native reminder',
    (tester) async {
      // Match production storage: Android can reclaim cache during low-space installs.
      final directory = await getApplicationSupportDirectory();
      final path =
          '${directory.path}/qa-${DateTime.now().millisecondsSinceEpoch}.db';
      final db = await databaseFactoryIo.openDatabase(path);
      final repo = LocalRepository(db);
      await repo.saveSettings({'onboarded': true, 'name': 'Amina'});
      final reminders = ReminderService();
      await reminders.initialize();
      final app = LocalTestController(repo, reminders);
      await app.initialize();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => app)],
          child: const DaryeelApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add medicine'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'QA vitamin');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Continue'));
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('Dosage')), '1 tablet');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      for (var step = 0; step < 2; step++) {
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Continue'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(app.medicines.single.name, 'QA vitamin');
      final dose = app.today.first;
      await app.updateDose(dose, DoseStatus.taken);
      await tester.pumpAndSettle();
      expect(app.today.single.recordedStatus, DoseStatus.taken);
      expect(app.today.single.completedAt, isNotNull);
      expect(
        reminders.allowed,
        isTrue,
        reason: 'Grant POST_NOTIFICATIONS using adb before running this test.',
      );
      await reminders.test();
      final pending = await reminders.plugin.pendingNotificationRequests();
      expect(pending.any((n) => n.payload == 'test'), isTrue);
      await Future<void>.delayed(const Duration(seconds: 20));
      final active = await reminders.plugin.getActiveNotifications();
      expect(
        active.any((n) => n.title == 'Daryeel test'),
        isTrue,
        reason:
            'Exact alarm permission must be enabled for deterministic timing.',
      );
      await reminders.plugin.cancelAll();
      expect(tester.takeException(), isNull);
      final beforeClose = await repo.all('guest');
      expect(
        beforeClose.any(
          (r) => r['kind'] == 'dose' && (r['data'] as Map)['status'] == 'taken',
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await db.close();
      final reopened = await databaseFactoryIo.openDatabase(path);
      final saved = await LocalRepository(reopened).all('guest');
      expect(
        saved.any(
          (r) => r['kind'] == 'dose' && (r['data'] as Map)['status'] == 'taken',
        ),
        isTrue,
        reason:
            'Before close: $beforeClose. After reopening: $saved. File: ${await File(path).readAsString()}',
      );
      await reopened.close();
      await File(path).delete();
    },
  );
}
