import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'timeline_providers.dart';

/// On-device reminders for «جدول إمتى» — no server or Firebase needed:
/// every date is known from the birth date, so the phone schedules them itself.
class TimelineReminders {
  TimelineReminders._();

  static final instance = TimelineReminders._();

  static const _maxScheduled = 40; // iOS keeps at most 64 pending.
  static const _horizonDays = 180;
  static const _firstId = 1000;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _lastSignature;

  Future<bool> _init() async {
    if (_initialized) return true;
    if (kIsWeb) return false;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Reminders] init failed: $e');
    }
    return _initialized;
  }

  Future<void> _requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> disable() async {
    if (!await _init()) return;
    _lastSignature = null;
    await _cancelOwn();
  }

  /// Only our id range — never wipe subscription / other local notifies.
  Future<void> _cancelOwn() async {
    for (var i = 0; i < _maxScheduled; i++) {
      await _plugin.cancel(id: _firstId + i);
    }
  }

  /// Re-schedules everything coming up. Cheap to call on every app open.
  Future<void> sync(TimelineData data, {bool force = false}) async {
    final birth = data.child?.birthDate;
    if (birth == null || !await _init()) return;

    final now = DateTime.now();
    final planned = <({DateTime at, String title, String body})>[];
    for (final item in data.items) {
      final day = DateTime(birth.year, birth.month, birth.day + item.ageDays);
      if (day.difference(now).inDays > _horizonDays) continue;
      planned.add((
        at: DateTime(day.year, day.month, day.day, 10),
        title: item.title,
        body: item.tips.isNotEmpty ? 'جربي النهارده: ${item.tips.first}' : item.body,
      ));
    }
    final upcoming = planned.where((p) => p.at.isAfter(now.add(const Duration(minutes: 1)))).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final batch = upcoming.take(_maxScheduled).toList();

    final signature = batch.map((p) => '${p.at.toIso8601String()}|${p.title}').join(';');
    if (!force && signature == _lastSignature) return;

    try {
      if (batch.isNotEmpty) await _requestPermission();
      await _cancelOwn();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'timeline_reminders',
          'مواعيد طفلك',
          channelDescription: 'مهارات وأكل حسب عمر طفلك',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      );
      for (var i = 0; i < batch.length; i++) {
        final p = batch[i];
        await _plugin.zonedSchedule(
          id: _firstId + i,
          scheduledDate: tz.TZDateTime.from(p.at, tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: p.title,
          body: p.body,
          payload: 'timeline',
        );
      }
      _lastSignature = signature;
    } catch (e) {
      if (kDebugMode) debugPrint('[Reminders] schedule failed: $e');
    }
  }
}
