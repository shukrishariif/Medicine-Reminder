import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:daryeel/data/models.dart';
import 'auth_test.dart' show makeController, mount;

void main() {
  testWidgets(
    'medicine details show real data and confirm deletion and preserve refill actions',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = (await tester.runAsync(() async {
        final app = await makeController('details-ui');
        await app.continueAsGuest();
        await app.saveMedicine(
          Medicine(
            id: 'details',
            name: 'Prescribed syrup',
            dosage: 'User-entered dose',
            type: 'Syrup',
            start: DateTime.now(),
            times: [480, 1200],
            weekdays: [1, 3, 5],
            treatmentDays: 5,
            refillAt: DateTime.now().add(const Duration(days: 7)),
          ),
        );
        return app;
      }))!;
      await mount(tester, app);
      GoRouter.of(
        tester.element(find.byTooltip('Add medicine')),
      ).go('/medicine/details');
      await tester.pumpAndSettle();
      expect(find.text('Medicine details'), findsOneWidget);
      expect(find.text('Prescribed syrup'), findsOneWidget);
      expect(find.text('User-entered dose'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(Switch));
      await tester.runAsync(() async {
        await tester.tap(find.byType(Switch));
        await app.settleAccount();
      });
      await tester.pumpAndSettle();
      expect(app.medicines.single.refillAt, isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      final archive = find.text('Delete Medicine');
      await tester.scrollUntilVisible(
        archive,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(archive);
        await app.settleAccount();
      });
      await tester.pumpAndSettle();
      expect(app.medicines, hasLength(1));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(app.medicines, hasLength(1));
      await tester.runAsync(() => tester.tap(archive));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await app.settleAccount();
      });
      await tester.pumpAndSettle();
      expect(app.medicines, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => app.repository.db.close());
    },
  );
}
