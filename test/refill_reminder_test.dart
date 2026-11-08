import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:daryeel/data/models.dart';
import 'package:daryeel/services/reminders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'refills schedule independently and cancel on removal without losing dose alarms',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      FlutterLocalNotificationsPlatform.instance =
          AndroidFlutterLocalNotificationsPlugin();
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.UTC);
      final calls = <MethodCall>[];
      final pending = <Map<String, dynamic>>[];
      var notificationsAllowed = true;
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        switch (call.method) {
          case 'areNotificationsEnabled':
            return notificationsAllowed;
          case 'canScheduleExactNotifications':
            return true;
          case 'pendingNotificationRequests':
            return pending;
          case 'getActiveNotifications':
            return <Map<String, dynamic>>[];
          case 'zonedSchedule':
            final args = Map<String, dynamic>.from(call.arguments);
            pending.add({
              'id': args['id'],
              'title': args['title'],
              'body': args['body'],
              'payload': args['payload'],
            });
            return null;
          default:
            return null;
        }
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final tomorrow = dayOnly(DateTime.now()).add(const Duration(days: 1));
      final m = Medicine(
        id: 'refill-test',
        name: 'Private medicine',
        dosage: 'Label dose',
        start: tomorrow,
        times: [480],
        refillAt: tomorrow.add(const Duration(hours: 9)),
      );
      final service = ReminderService()..available = true;
      final doses = generateDoses([m], tomorrow, tomorrow);
      await service.reconcile(doses, [m], {'privateNotifications': true});
      final scheduled = calls
          .where((c) => c.method == 'zonedSchedule')
          .map((c) => Map<String, dynamic>.from(c.arguments))
          .toList();
      expect(scheduled.length, 2);
      final refill = scheduled.singleWhere(
        (c) => c['payload'] == 'refill:refill-test',
      );
      expect(refill['body'], isNot(contains(m.name)));
      expect(scheduled.any((c) => c['payload'] == doses.single.id), isTrue);
      calls.clear();
      await service.reconcile(doses, [m], {'privateNotifications': true});
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
      calls.clear();
      await service.reconcile(
        doses,
        [
          m.change({'refillAt': null}),
        ],
        {'privateNotifications': true},
      );
      expect(
        calls.where((c) => c.method == 'cancel').map((c) => c.arguments['id']),
        contains(refill['id']),
      );
      expect(calls.where((c) => c.method == 'cancel').length, 1);
      notificationsAllowed = false;
      calls.clear();
      await expectLater(service.test(), throwsStateError);
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    },
  );
}
