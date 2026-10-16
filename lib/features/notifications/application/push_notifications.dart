import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../community/presentation/club_group_screen.dart';
import '../../courses/data/courses_repository.dart';
import '../../courses/domain/course.dart';
import '../../courses/presentation/course_detail_screen.dart';
import '../../support/presentation/consultations_screen.dart';
import '../data/notifications_cloud_repository.dart';
import '../presentation/notifications_screen.dart';

/// Server push (FCM) + local reminders. Firebase settings come from dart_defines —
/// without them the app still schedules on-device renewal nudges.
class PushNotifications {
  PushNotifications._();

  static final instance = PushNotifications._();

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  /// Must match `default_notification_channel_id` in AndroidManifest.xml.
  static const channelId = 'bayanour_news';
  static const renewalChannelId = 'subscription_renewal';
  static const renewalNotificationId = 9100;

  static bool get isConfigured =>
      !kIsWeb &&
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty;

  final _local = FlutterLocalNotificationsPlugin();
  bool _localReady = false;
  bool _fcmStarted = false;
  StreamSubscription<String>? _refreshSub;
  String? _renewalSignature;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      'أخبار بيانور',
      channelDescription: 'رسائل الإدارة والاستشارات ومواعيد اللايف',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<bool> _ensureLocal() async {
    if (_localReady) return true;
    if (kIsWeb) return false;
    try {
      tzdata.initializeTimeZones();
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => _openPayload(r.payload),
      );
      final android = _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          'أخبار بيانور',
          description: 'رسائل الإدارة والاستشارات ومواعيد اللايف',
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          renewalChannelId,
          'تجديد الباقة',
          description: 'تذكير قبل ما الباقة تخلص عشان تتفتح دروس جديدة',
          importance: Importance.high,
        ),
      );
      _localReady = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] local init failed: $e');
    }
    return _localReady;
  }

  Future<bool> _startFcm() async {
    if (_fcmStarted) return true;
    if (!isConfigured || !await _ensureLocal()) return false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: _apiKey,
            appId: _appId,
            messagingSenderId: _senderId,
            projectId: _projectId,
          ),
        );
      }
      // Android doesn't show FCM notifications while the app is open.
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        // Cold start: let the splash/auth redirects settle first.
        Future.delayed(const Duration(seconds: 3), () => _openMessage(initial));
      }
      _fcmStarted = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] FCM init failed: $e');
    }
    return _fcmStarted;
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      id: message.hashCode & 0x7fffffff,
      title: n.title,
      body: n.body,
      notificationDetails: _details,
      payload: '${message.data['kind'] ?? ''}|${_targetId(message.data) ?? ''}',
    );
  }

  static String? _targetId(Map<String, dynamic> data) =>
      (data['course_id'] ?? data['group_id']) as String?;

  void _openMessage(RemoteMessage m) => _openFor(m.data['kind'] as String?, _targetId(m.data));

  /// Local notification payload: `kind|targetId` (course or club group id).
  void _openPayload(String? payload) {
    final parts = (payload ?? '').split('|');
    _openFor(parts.first, parts.length > 1 ? parts[1] : null);
  }

  /// Consultation replies open «طلباتي», live reminders open the live's course
  /// (where the countdown is), group announcements open the group; subscription
  /// renewal opens plans; everything else opens the notifications list.
  Future<void> _openFor(String? kind, [String? targetId]) async {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    if (kind == 'subscription') {
      final ctx = nav.context;
      if (!ctx.mounted) return;
      ctx.push(
        AppRoutes.subscription,
        extra: 'جدّدي الباقة عشان تتفتح دروس جديدة لطفلك.',
      );
      return;
    }
    if (kind == 'club_group') {
      if (targetId == null || targetId.isEmpty) return;
      nav.push(MaterialPageRoute<void>(builder: (_) => ClubGroupScreen(groupId: targetId)));
      return;
    }
    if (kind == 'live') {
      if (targetId == null || targetId.isEmpty) return;
      final courses = await ProviderScope.containerOf(nav.context, listen: false)
          .read(coursesProvider.future)
          .catchError((_) => const <Course>[]);
      final course = courses.where((c) => c.id == targetId).firstOrNull;
      if (course == null || !nav.mounted) return;
      nav.push(
        MaterialPageRoute<void>(builder: (_) => CourseDetailScreen(course: course)),
      );
      return;
    }
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => kind == 'consultation'
            ? const ConsultationsScreen()
            : const NotificationsScreen(),
      ),
    );
  }

  Future<void> _requestPermission() async {
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _local
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> cancelSubscriptionRenewal() async {
    if (!await _ensureLocal()) return;
    await _local.cancel(id: renewalNotificationId);
    _renewalSignature = null;
  }

  /// Schedules one local nudge ~1 week before [expiresAt], or when lesson runway ≤ 7.
  Future<void> syncSubscriptionRenewal({
    required DateTime? expiresAt,
    required int lessonDaysLeft,
  }) async {
    if (!await _ensureLocal()) return;

    final now = DateTime.now();
    DateTime? fireAt;
    late final String body;

    final expiryLocal = expiresAt?.toLocal();
    if (expiryLocal != null && expiryLocal.isAfter(now)) {
      final weekBefore = expiryLocal.subtract(const Duration(days: 7));
      if (weekBefore.isAfter(now.add(const Duration(minutes: 2)))) {
        fireAt = DateTime(weekBefore.year, weekBefore.month, weekBefore.day, 10);
      } else {
        fireAt = DateTime(now.year, now.month, now.day + 1, 10);
        if (!fireAt.isBefore(expiryLocal)) fireAt = null;
      }
      body = 'باقي أسبوع على نهاية باقتكِ تقريباً — جدّدي عشان تتفتح دروس جديدة.';
    } else if (lessonDaysLeft > 0 && lessonDaysLeft <= 7) {
      fireAt = DateTime(now.year, now.month, now.day + 1, 10);
      body = lessonDaysLeft <= 1
          ? 'الأيام المفتوحة خلصت تقريباً — مدّي الاشتراك عشان دروس جديدة تتفتح.'
          : 'فاضل $lessonDaysLeft أيام مفتوحين — مدّي الاشتراك عشان طفلك يكمل.';
    } else {
      await cancelSubscriptionRenewal();
      return;
    }

    if (fireAt == null || !fireAt.isAfter(now.add(const Duration(minutes: 1)))) {
      await cancelSubscriptionRenewal();
      return;
    }

    final signature =
        '${fireAt.toIso8601String()}|${expiryLocal?.toIso8601String() ?? ''}|$lessonDaysLeft';
    if (signature == _renewalSignature) return;

    try {
      await _requestPermission();
      await _local.cancel(id: renewalNotificationId);
      await _local.zonedSchedule(
        id: renewalNotificationId,
        scheduledDate: tz.TZDateTime.from(fireAt, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            renewalChannelId,
            'تجديد الباقة',
            channelDescription: 'تذكير قبل ما الباقة تخلص عشان تتفتح دروس جديدة',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'جدّدي باقة بيانور',
        body: body,
        payload: 'subscription|',
      );
      _renewalSignature = signature;
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] renewal schedule failed: $e');
    }
  }

  /// Asks for permission and saves this device's token for the signed-in user.
  /// Returns false when push isn't configured, so the caller can fall back.
  Future<bool> register(NotificationsCloudRepository repo) async {
    if (!await _startFcm()) return false;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return false;
      final platform = defaultTargetPlatform.name;
      await repo.upsertDeviceToken(token: token, platform: platform);
      await _refreshSub?.cancel();
      _refreshSub = messaging.onTokenRefresh.listen(
        (t) => repo.upsertDeviceToken(token: t, platform: platform),
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] register failed: $e');
      return false;
    }
  }
}
