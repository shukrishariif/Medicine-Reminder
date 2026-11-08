import 'dart:async';
import 'dart:convert';
import 'package:sembast/sembast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'reminders.dart';

final appProvider = ChangeNotifierProvider<AppController>(
  (ref) => throw UnimplementedError('Override at startup'),
);

class AppController extends ChangeNotifier {
  final LocalRepository repository;
  final ReminderService reminders;
  final SupabaseClient? cloud;
  Json settings = {};
  List<Medicine> medicines = [];
  Map<String, Dose> records = {};
  String? error, syncMessage;
  String? authNotice;
  bool syncing = false;
  bool recoveringPassword = false;
  bool _switchingAccount = false;
  bool get guestMode =>
      !signedIn && owner == 'guest' && settings['guestMode'] == true;
  bool get canAccessApp =>
      !_switchingAccount &&
      (guestMode || (signedIn && owner == cloud?.auth.currentUser?.id));
  Future<void> settleAccount() => _queue;
  String owner = 'guest';
  Timer? _timer;
  Timer? _syncTimer;
  void scheduleSync() {
    if (!signedIn) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(run(sync));
    });
  }

  StreamSubscription<AuthState>? _auth;
  Future<void> _queue = Future.value();
  AppController(this.repository, this.reminders, {this.cloud});
  String get name => signedIn
      ? (settings['name.$owner'] as String? ??
            cloud?.auth.currentUser?.userMetadata?['full_name'] as String? ??
            'Friend')
      : settings['name'] as String? ?? 'Friend';
  String get language => settings['language'] as String? ?? 'en';
  bool get onboarded => settings['onboarded'] == true;
  bool get signedIn => cloud?.auth.currentUser != null;
  Future<void> initialize() async {
    settings = await repository.settings();
    owner = cloud?.auth.currentUser?.id ?? 'guest';
    await reload();
    await materialize();
    await refreshReminders();
    _auth = cloud?.auth.onAuthStateChange.listen(
      (event) {
        authNotice = null;
        if (event.event == AuthChangeEvent.passwordRecovery) {
          recoveringPassword = true;
        }
        if (event.session == null) recoveringPassword = false;
        if (owner != (event.session?.user.id ?? 'guest')) {
          _switchingAccount = true;
          medicines = [];
          records = {};
        }
        notifyListeners();
        unawaited(_authChanged(event.session?.user.id));
      },
      onError: (Object error, StackTrace stack) {
        authNotice = 'Sign-in link could not be verified. Request a new link.';
        recoveringPassword = false;
        notifyListeners();
      },
    );
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
      unawaited(
        run(() async {
          await materialize();
          await refreshReminders();
          if (signedIn) {
            await sync();
          }
        }),
      );
    });
  }

  Future<void> _authChanged(String? userId) => run(() async {
    if (userId != null && settings['guestMode'] == true) {
      settings['guestMode'] = false;
      await repository.saveSettings(settings);
    }
    final next = userId ?? 'guest';
    if (next != owner) {
      owner = next;
      await reload();
      await materialize();
      _switchingAccount = false;
      await refreshReminders();
    }
    if (userId != null) {
      await sync();
    }
    notifyListeners();
  });
  Future<void> reload() async {
    final rows = await repository.all(owner);
    medicines = rows
        .where((r) => r['kind'] == 'medicine' && r['deleted'] != true)
        .map((r) => Medicine.fromJson(Map<String, dynamic>.from(r['data'])))
        .toList();
    records = {
      for (final r in rows.where(
        (r) => r['kind'] == 'dose' && r['deleted'] != true,
      ))
        r['id'] as String: Dose.fromJson(Map<String, dynamic>.from(r['data'])),
    };
    notifyListeners();
  }

  Future<void> continueAsGuest() => run(() async {
    if (signedIn) return;
    owner = 'guest';
    settings = {...settings, 'guestMode': true, 'onboarded': true};
    await repository.saveSettings(settings);
    await reload();
    await materialize();
    await refreshReminders();
  });

  List<Dose> doses(DateTime from, DateTime to) {
    final generated = {
      for (final d in generateDoses(medicines, from, to)) d.id: d,
    };
    for (final d in records.values) {
      if (!dayOnly(d.scheduled).isBefore(dayOnly(from)) &&
          !dayOnly(d.scheduled).isAfter(dayOnly(to))) {
        generated[d.id] = d;
      }
    }
    return generated.values.toList()..sort(
      (a, b) => (a.snoozedUntil ?? a.scheduled).compareTo(
        b.snoozedUntil ?? b.scheduled,
      ),
    );
  }

  List<Dose> get today => doses(DateTime.now(), DateTime.now());
  Future<void> materialize() async {
    // Persist elapsed occurrences so later edits cannot rewrite history.
    final now = DateTime.now();
    final last =
        DateTime.tryParse(settings['lastMaterialized.$owner'] ?? '') ?? now;
    final from = last.isBefore(now.subtract(const Duration(days: 365)))
        ? now.subtract(const Duration(days: 365))
        : last;
    for (final d in generateDoses(medicines, from, now)) {
      if (!d.scheduled.isAfter(now) && !records.containsKey(d.id)) {
        await repository.put(owner, 'dose', d.id, d.toJson());
        records[d.id] = d;
      }
    }
    settings['lastMaterialized.$owner'] = now.toIso8601String();
    await repository.saveSettings(settings);
  }

  Future<void> run(Future<void> Function() work) {
    final result = _queue.then((_) async {
      error = null;
      try {
        await work();
      } catch (e) {
        error =
            e is FormatException &&
                const {
                  'Enter a medicine name and dosage.',
                  'Choose 1–12 different reminder times.',
                  'Choose at least one weekday.',
                  'Enter an interval from 1 to 365 days.',
                  'End date must follow the start date.',
                  'Repeat reminders must be between 0 and 3.',
                  'Choose 5, 10 or 15 minutes.',
                  'Sign in first.',
                  'Unsupported backup file.',
                  'Invalid backup record.',
                  'Invalid record identifier.',
                }.contains(e.message)
            ? e.message
            : 'Unable to finish this action. Your saved data is retained.';
      }
      notifyListeners();
    });
    _queue = result;
    return result;
  }

  Future<void> saveMedicine(Medicine m) => run(() async {
    m.validate();
    await materialize();
    await repository.put(owner, 'medicine', m.id, m.toJson());
    // Remove unresolved future snoozes invalidated by schedule changes.
    for (final d in records.values.where(
      (d) =>
          d.medicineId == m.id &&
          !d.resolved &&
          d.scheduled.isAfter(DateTime.now()),
    )) {
      await repository.put(owner, 'dose', d.id, d.toJson(), deleted: true);
    }
    await reload();
    await refreshReminders();
    scheduleSync();
  });
  Future<void> deleteMedicine(Medicine m) => run(() async {
    await materialize();
    await repository.put(owner, 'medicine', m.id, m.toJson(), deleted: true);
    await reload();
    await refreshReminders();
    scheduleSync();
  });
  Future<void> updateDose(Dose d, DoseStatus status, {int? snoozeMinutes}) =>
      run(() async {
        if (snoozeMinutes != null && ![5, 10, 15].contains(snoozeMinutes)) {
          throw const FormatException('Choose 5, 10 or 15 minutes.');
        }
        final latest = records[d.id] ?? d;
        if (latest.resolved) {
          return;
        }
        final updated = latest.change({
          'status': status.name,
          'completedAt':
              status == DoseStatus.taken || status == DoseStatus.skipped
              ? DateTime.now().toUtc().toIso8601String()
              : null,
          'snoozedUntil': snoozeMinutes == null
              ? null
              : DateTime.now()
                    .add(Duration(minutes: snoozeMinutes))
                    .toUtc()
                    .toIso8601String(),
        });
        await repository.put(owner, 'dose', d.id, updated.toJson());
        await reminders.cancelDose(d.id);
        await reload();
        await refreshReminders();
        scheduleSync();
      });
  Future<void> setSettings(Json changes) => run(() async {
    if (signedIn && changes.containsKey('name')) {
      final fullName = changes['name'];
      await cloud!.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
      changes = {...changes}..remove('name');
      changes['name.$owner'] = fullName;
    }
    settings = {...settings, ...changes};
    await repository.saveSettings(settings);
    await refreshReminders();
  });
  Future<void> refreshReminders() async {
    try {
      await reminders.reconcile(
        canAccessApp
            ? doses(
                DateTime.now(),
                DateTime.now().add(const Duration(days: 30)),
              )
            : [],
        canAccessApp ? medicines : [],
        settings,
      );
    } catch (_) {
      error =
          'Saved locally, but reminders could not be scheduled. Check alarm permissions and reopen Daryeel.';
    }
  }

  Future<void> resume() => run(() async {
    await reminders.refreshTimezone();
    await materialize();
    await refreshReminders();
    if (signedIn) {
      await sync();
    }
  });
  Future<void> finishRecovery() async {
    recoveringPassword = false;
    notifyListeners();
  }

  Future<void> sync() async {
    final session = cloud?.auth.currentSession;
    if (session == null || session.user.id != owner || syncing) {
      return;
    }
    syncing = true;
    notifyListeners();
    final syncOwner = owner;
    try {
      final dirty = (await repository.all(syncOwner))
          .where((r) => r['dirty'] == true)
          .map(
            (r) => {
              'kind': r['kind'],
              'id': r['id'],
              'data': r['data'],
              'deleted': r['deleted'],
              'modified': r['modified'],
            },
          )
          .toList();
      // Server performs atomic timestamp comparison and enforces auth.uid().
      final result = await cloud!
          .rpc('sync_records', params: {'changes': dirty})
          .setHeader('Authorization', 'Bearer ${session.accessToken}');
      await repository.merge(
        syncOwner,
        (result as List).map((r) => Map<String, dynamic>.from(r)).toList(),
      );
      if (owner == syncOwner && cloud?.auth.currentUser?.id == syncOwner) {
        await reload();
        await refreshReminders();
      }
      syncMessage = 'Cloud backup is up to date';
    } catch (_) {
      syncMessage =
          'Offline or cloud unavailable. Changes are saved on this device and will retry.';
    }
    syncing = false;
    notifyListeners();
  }

  Future<void> importGuest() => run(() async {
    if (!signedIn) {
      throw const FormatException('Sign in first.');
    }
    await repository.migrateGuest(owner);
    await reload();
    await sync();
  });
  Future<String> exportBackup() async => const JsonEncoder.withIndent(
    '  ',
  ).convert({'version': 1, 'records': await repository.all(owner)});
  Future<void> restoreBackup(String text) => run(() async {
    final dynamic parsed;
    try {
      parsed = jsonDecode(text);
    } on FormatException {
      throw const FormatException('Unsupported backup file.');
    }
    if (parsed is! Map ||
        parsed['version'] != 1 ||
        parsed['records'] is! List) {
      throw const FormatException('Unsupported backup file.');
    }
    final rows = <Json>[];
    for (final item in parsed['records']) {
      final row = Map<String, dynamic>.from(item);
      if (!['medicine', 'dose'].contains(row['kind'])) {
        throw const FormatException('Invalid backup record.');
      }
      final data = Map<String, dynamic>.from(row['data']);
      if (row['kind'] == 'medicine') {
        Medicine.fromJson(data).validate();
      } else {
        Dose.fromJson(data);
      }
      if (data['id'] != row['id']) {
        throw const FormatException('Invalid record identifier.');
      }
      rows.add(row);
    }
    await repository.db.transaction((txn) async {
      for (final row in rows) {
        await repository.records
            .record('$owner/${row['kind']}/${row['id']}')
            .put(txn, {
              ...row,
              'owner': owner,
              'dirty': true,
              'modified': DateTime.now().toUtc().toIso8601String(),
            });
      }
    });
    await reload();
    await refreshReminders();
    scheduleSync();
  });
  Future<void> deleteAccount() => run(() async {
    if (!signedIn) {
      return;
    }
    final deletedOwner = owner;
    await cloud!.rpc('delete_my_account');
    await repository.clearOwner(deletedOwner);
    await cloud!.auth.signOut(scope: SignOutScope.local);
    owner = 'guest';
    await reload();
    await refreshReminders();
  });
  @override
  void dispose() {
    _timer?.cancel();
    _syncTimer?.cancel();
    _auth?.cancel();
    super.dispose();
  }
}
