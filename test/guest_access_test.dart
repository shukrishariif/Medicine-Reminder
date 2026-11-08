import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daryeel/data/models.dart';
import 'package:daryeel/services/app_controller.dart';
import 'package:daryeel/services/reminders.dart';
import 'package:daryeel/features/account_auth.dart';
import 'package:go_router/go_router.dart';
import 'auth_test.dart' show makeController, mount, AuthContract;

void main() {
  testWidgets('guest button opens home and still permits account sign in', (
    tester,
  ) async {
    final app = (await tester.runAsync(
      () => makeController('guest-navigation'),
    ))!;
    await mount(tester, app);
    final button = find.widgetWithText(TextButton, 'Continue as guest');
    await tester.ensureVisible(button);
    await tester.runAsync(() async {
      await tester.tap(button);
      await app.settleAccount();
    });
    await tester.pumpAndSettle();
    expect(app.guestMode, isTrue);
    expect(app.signedIn, isFalse);
    expect(find.byTooltip('Add medicine'), findsOneWidget);
    GoRouter.of(tester.element(find.byTooltip('Add medicine'))).go('/auth');
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => app.repository.db.close());
  });

  test(
    'guest medicines survive restart and stay separate from real accounts',
    () async {
      final api = AuthContract();
      final app = await makeController('guest-persistence', cloud: api.client);
      await app.continueAsGuest();
      await app.saveMedicine(
        Medicine(
          id: 'guest-medicine',
          name: 'User medicine',
          dosage: 'User dose',
          start: DateTime.now(),
          times: [480],
        ),
      );
      final repo = app.repository;
      app.dispose();
      final restored = AppController(
        repo,
        ReminderService(),
        cloud: api.client,
      );
      await restored.initialize();
      expect(restored.canAccessApp, isTrue);
      expect(restored.medicines.single.id, 'guest-medicine');
      await api.client.auth.signInWithPassword(
        email: 'a@example.com',
        password: 'test-pass',
      );
      await Future<void>.delayed(Duration.zero);
      await restored.settleAccount();
      expect(restored.guestMode, isFalse);
      expect(restored.medicines, isEmpty);
      expect(await repo.all('guest'), isNotEmpty);
      await api.client.auth.signOut();
      await Future<void>.delayed(Duration.zero);
      await restored.settleAccount();
      expect(restored.canAccessApp, isFalse);
      await restored.continueAsGuest();
      expect(restored.medicines.single.id, 'guest-medicine');
      restored.dispose();
      await repo.db.close();
      await api.client.dispose();
    },
  );
}
