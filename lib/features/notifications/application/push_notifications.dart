import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../community/presentation/club_group_screen.dart';
import '../../courses/data/courses_repository.dart';
import '../../courses/domain/course.dart';
import '../../courses/presentation/course_detail_screen.dart';
import '../../support/presentation/consultations_screen.dart';
import '../data/notifications_cloud_repository.dart';
import '../presentation/notifications_screen.dart';

/// Server push (FCM). Firebase settings come from dart_defines — no
/// google-services.json. Without them the app keeps in-app notifications only.
class PushNotifications {
  PushNotifications._();

  static final instance = PushNotifications._();

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  /// Must match `default_notification_channel_id` in AndroidManifest.xml.
  static const channelId = 'bayanour_news';

  static bool get isConfigured =>
      !kIsWeb &&
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty;

  final _local = FlutterLocalNotificationsPlugin();
  bool _started = false;
  StreamSubscription<String>? _refreshSub;

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

  Future<bool> _start() async {
    if (_started) return true;
    if (!isConfigured) return false;
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
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              'أخبار بيانور',
              description: 'رسائل الإدارة والاستشارات ومواعيد اللايف',
              importance: Importance.high,
            ),
          );
      // Android doesn't show FCM notifications while the app is open.
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        // Cold start: let the splash/auth redirects settle first.
        Future.delayed(const Duration(seconds: 3), () => _openMessage(initial));
      }
      _started = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] init failed: $e');
    }
    return _started;
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
  /// (where the countdown is), group announcements open the group; everything
  /// else opens the notifications list.
  Future<void> _openFor(String? kind, [String? targetId]) async {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
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

  /// Asks for permission and saves this device's token for the signed-in user.
  /// Returns false when push isn't configured, so the caller can fall back.
  Future<bool> register(NotificationsCloudRepository repo) async {
    if (!await _start()) return false;
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
