import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service to handle push notifications (FCM + local).
///
/// Attendance alerts are NOT handled here anymore — they are handled by the
/// scheduled daily check in background_service.dart.  This service only
/// manages notification channel setup, permissions, and FCM foreground messages.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  int _notificationId = 0;

  /// Initialize notification channels and permissions
  Future<void> initialize() async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications for Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize local notifications for iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Create notification channel for Alerts (High Importance)
    final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          'attendance_alerts',
          'Attendance Alerts',
          description: 'Notifications for low attendance warnings',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Create notification channel for Service (Low Importance)
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          'attendance_service_channel',
          'Background Service',
          description: 'Keeps the app running to monitor attendance',
          importance: Importance.low,
          showBadge: false,
        ),
      );
    }

    // Handle foreground messages from FCM
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Get FCM token for server-side push (for future use)
    try {
      await _firebaseMessaging.getToken();
      developer.log('FCM Token obtained successfully', name: 'NotificationService');
    } catch (e) {
      developer.log('Warning: Failed to get FCM token: $e', name: 'NotificationService');
      // Non-fatal error. The app should continue to load.
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    showNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
    );
  }

  /// Show a local notification
  Future<void> showNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_alerts',
      'Attendance Alerts',
      channelDescription: 'Notifications for low attendance warnings',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    _notificationId++;
    await _localNotifications.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}