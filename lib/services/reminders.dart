import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../data/models.dart';
import '../core/strings.dart';

class ReminderService {
  final plugin = FlutterLocalNotificationsPlugin();
  bool available = false, allowed = false, exact = false;
  String? launchDose;
  void Function(String)? onOpen;
  final Map<String, int> _ids = {};
  final Map<int, String> _fingerprints = {};
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<void> initialize() async {
    if (!supported) {
      return;
    }
    tzdata.initializeTimeZones();
    await refreshTimezone();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload != null) {
          onOpen?.call(r.payload!);
        }
      },
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      launchDose = launch?.notificationResponse?.payload;
    }
    available = true;
    await refreshPermissions();
  }

  Future<void> refreshTimezone() async {
    if (!supported) {
      return;
    }
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
  }

  Future<void> refreshPermissions() async {
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    allowed = await android?.areNotificationsEnabled() ?? false;
    exact = await android?.canScheduleExactNotifications() ?? false;
  }

  Future<void> requestPermissions({
    bool precise = false,
    bool fullScreen = false,
  }) async {
    if (!available) {
      return;
    }
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    if (precise) {
      await android?.requestExactAlarmsPermission();
    }
    if (fullScreen) {
      await android?.requestFullScreenIntentPermission();
    }
    await refreshPermissions();
  }

  int idFor(String key) {
    // Deterministic 31-bit FNV hash; collision resolution inside each complete plan.
    var hash = 2166136261;
    for (final c in key.codeUnits) {
      hash = ((hash ^ c) * 16777619) & 0x7fffffff;
    }
    while (_ids.containsValue(hash) && _ids[key] != hash) {
      hash = (hash + 1) & 0x7fffffff;
    }
    _ids[key] = hash;
    return hash;
  }

  NotificationDetails details({
    bool fullScreen = false,
    String language = 'en',
    bool private = true,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      'medicine_reminders_v1',
      AppStrings(language)('Medicine reminders'),
      channelDescription: AppStrings(language)(
        'Scheduled medication reminders',
      ),
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      visibility: private
          ? NotificationVisibility.private
          : NotificationVisibility.public,
      fullScreenIntent: fullScreen,
      actions: [
        AndroidNotificationAction(
          'open',
          language == 'ar'
              ? 'فتح التذكير'
              : language == 'so'
              ? 'Fur xusuusinta'
              : 'Open reminder',
          showsUserInterface: true,
        ),
      ],
    ),
  );
  Future<void> schedule(
    Dose dose,
    DateTime time, {
    String suffix = '',
    bool fullScreen = false,
    String language = 'en',
    bool private = true,
  }) async {
    if (!available || !allowed || !time.isAfter(DateTime.now())) {
      return;
    }
    await plugin.zonedSchedule(
      idFor('${dose.id}$suffix'),
      private
          ? (language == 'ar'
                ? 'تذكير الدواء'
                : language == 'so'
                ? 'Xusuusin daawo'
                : 'Medicine reminder')
          : dose.name,
      private
          ? (language == 'ar'
                ? 'افتح للاطلاع على التفاصيل'
                : language == 'so'
                ? 'Fur si aad u aragto faahfaahinta'
                : 'Open to view your scheduled dose')
          : '${dose.dosage} • ${dose.name}',
      tz.TZDateTime.from(time, tz.local),
      details(fullScreen: fullScreen, language: language, private: private),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: dose.id,
    );
  }

  Future<void> reconcile(
    List<Dose> doses,
    List<Medicine> medicines,
    Json settings,
  ) async {
    if (!available) {
      return;
    }
    await refreshPermissions();
    if (settings['notifications'] == false) {
      await plugin.cancelAll();
      _fingerprints.clear();
      return;
    }
    final pending = await plugin.pendingNotificationRequests();
    final pendingIds = pending.map((p) => p.id).toSet();
    final keep = <int>{idFor('test')};
    var count = 0;
    // Refill alerts use their own IDs and open medicine details, not a dose alarm.
    for (final medicine in medicines) {
      final at = medicine.refillAt;
      if (at == null || medicine.paused || medicine.archived) continue;
      final id = idFor('refill:${medicine.id}');
      keep.add(id);
      if (!allowed || !at.isAfter(DateTime.now())) continue;
      final language = settings['language'] as String? ?? 'en';
      final private = settings['privateNotifications'] != false;
      final fingerprint =
          '$at|${tz.local.name}|${medicine.name}|$language|$private|$exact';
      if (pendingIds.contains(id) && _fingerprints[id] == fingerprint) continue;
      await plugin.zonedSchedule(
        id,
        AppStrings(language)('Refill reminder'),
        private
            ? AppStrings(language)('Open to view medicine details')
            : medicine.name,
        tz.TZDateTime.from(at, tz.local),
        details(language: language, private: private),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'refill:${medicine.id}',
      );
      _fingerprints[id] = fingerprint;
      count++;
    }
    for (final dose in doses) {
      final matches = medicines.where((m) => m.id == dose.medicineId);
      if (dose.resolved ||
          matches.isEmpty ||
          !matches.first.reminders ||
          matches.first.paused ||
          matches.first.archived) {
        continue;
      }
      final time = dose.snoozedUntil ?? dose.scheduled;
      for (var repeat = 0; repeat <= matches.first.repeats; repeat++) {
        final at = time.add(Duration(minutes: repeat * 10));
        final id = idFor('${dose.id}_$repeat');
        // Keep a delivered notification visible until its dose is resolved.
        if (dose.snoozedUntil == null) {
          keep.add(id);
        }
        if (!at.isAfter(DateTime.now())) {
          continue;
        }
        if (++count > 450) {
          continue;
        }
        keep.add(id);
        final fingerprint =
            '$at|${tz.local.name}|${dose.name}|${dose.dosage}|${settings['fullScreen']}|${settings['language']}|${settings['privateNotifications']}|$exact';
        if (pendingIds.contains(id) && _fingerprints[id] == fingerprint) {
          continue;
        }
        await schedule(
          dose,
          at,
          suffix: '_$repeat',
          fullScreen: settings['fullScreen'] == true,
          language: settings['language'] ?? 'en',
          private: settings['privateNotifications'] != false,
        );
        _fingerprints[id] = fingerprint;
      }
    }
    final active = await plugin.getActiveNotifications();
    for (final id in {
      ...pendingIds,
      ...active.map((n) => n.id).whereType<int>(),
    }) {
      if (!keep.contains(id)) {
        await plugin.cancel(id);
        _fingerprints.remove(id);
      }
    }
  }

  Future<void> cancelDose(String doseId) async {
    if (!available) {
      return;
    }
    for (var i = 0; i <= 3; i++) {
      final id = idFor('${doseId}_$i');
      await plugin.cancel(id);
      _fingerprints.remove(id);
    }
  }

  Future<void> test({String language = 'en'}) async {
    await refreshPermissions();
    if (!available || !allowed) {
      throw StateError('Notification permission is required to test a reminder.');
    }
    final at = DateTime.now().add(const Duration(seconds: 15));
    await schedule(
      Dose(
        id: 'test',
        medicineId: 'test',
        name: AppStrings(language)('Daryeel test'),
        dosage: AppStrings(language)('Test reminder'),
        scheduled: at,
      ),
      at,
      private: false,
      language: language,
    );
  }
}
