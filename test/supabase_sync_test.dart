import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:daryeel/data/models.dart';
import 'package:daryeel/data/repository.dart';
import 'package:daryeel/services/app_controller.dart';
import 'package:daryeel/services/reminders.dart';
import 'auth_test.dart' show AuthContract, makeController;

class DelayedRepository extends LocalRepository {
  Completer<void>? gate;
  DelayedRepository(super.db);
  @override
  Future<List<Json>> all(String owner) async {
    final pending = gate;
    if (pending != null) await pending.future;
    return super.all(owner);
  }
}

void main() {
  test(
    'medicine writes promptly queue cloud sync with schedule and refill fields',
    () async {
      final api = AuthContract();
      final app = await makeController('prompt-sync', cloud: api.client);
      await api.client.auth.signInWithPassword(
        email: 'a@example.com',
        password: 'test-pass',
      );
      await Future<void>.delayed(Duration.zero);
      await app.settleAccount();
      final before = api.requests.length;
      await app.saveMedicine(
        Medicine(
          id: 'sync-medicine',
          name: 'Label medicine',
          dosage: 'Label dose',
          start: DateTime.now(),
          times: [480, 1200],
          weekdays: [1, 3, 5],
          refillAt: DateTime.now().add(const Duration(days: 5)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await app.settleAccount();
      final requests = api.requests
          .skip(before)
          .where((r) => r.url.path.endsWith('/sync_records'));
      expect(requests, isNotEmpty);
      final changes = jsonDecode(requests.last.body)['changes'] as List;
      final medicine = changes.singleWhere(
        (r) => r['kind'] == 'medicine',
      )['data'];
      expect(medicine['times'], [480, 1200]);
      expect(medicine['weekdays'], [1, 3, 5]);
      expect(medicine['refillAt'], isNotNull);
      app.dispose();
      await app.repository.db.close();
      await api.client.dispose();
    },
  );

  test(
    'an in-flight sync keeps the originating session token across account changes',
    () async {
      final api = AuthContract();
      final repo = DelayedRepository(
        await databaseFactoryMemory.openDatabase('sync-token-race'),
      );
      await repo.saveSettings({'onboarded': true});
      final app = AppController(repo, ReminderService(), cloud: api.client);
      await app.initialize();
      await api.client.auth.signInWithPassword(
        email: 'a@example.com',
        password: 'test-pass',
      );
      await Future<void>.delayed(Duration.zero);
      await app.settleAccount();
      final tokenA = api.client.auth.currentSession!.accessToken;
      final before = api.requests.length;
      final gate = Completer<void>();
      repo.gate = gate;
      final pending = app.sync();
      await api.client.auth.signOut();
      api.activeId = '22222222-2222-4222-8222-222222222222';
      await api.client.auth.signInWithPassword(
        email: 'b@example.com',
        password: 'test-pass',
      );
      repo.gate = null;
      gate.complete();
      await pending;
      await Future<void>.delayed(Duration.zero);
      await app.settleAccount();
      final requests = api.requests
          .skip(before)
          .where((r) => r.url.path.endsWith('/sync_records'))
          .toList();
      expect(requests, isNotEmpty);
      expect(requests.first.headers['Authorization'], 'Bearer $tokenA');
      expect(app.owner, api.activeId);
      app.dispose();
      await repo.db.close();
      await api.client.dispose();
    },
  );
}
