import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to stream notices from Firebase RTDB and send notifications for new ones.
/// Self-contained: uses its own notification channel so it doesn't touch
/// attendance notification logic at all.
class NoticeService {
  static final NoticeService _instance = NoticeService._internal();
  factory NoticeService() => _instance;
  NoticeService._internal();

  StreamSubscription<DatabaseEvent>? _childAddedSubscription;

  static const String _seenNoticeIdsKey = 'seen_notice_ids';
  static const String _noticeChannelId = 'notice_alerts';
  static const String _noticeChannelName = 'Notice Alerts';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  int _notifId = 5000; // offset to avoid collision with attendance notif IDs

  DatabaseReference get _noticesRef => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://studentsupporttest-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref().child('notices');

  /// Initialize the notification channel and plugin for notices.
  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(settings: initSettings);

    // Create a dedicated channel for notice alerts
    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _noticeChannelId,
          _noticeChannelName,
          description: 'Notifications for new notices',
          importance: Importance.high,
          playSound: true,
        ),
      );
    }
  }

  /// Show a notice notification on the dedicated channel.
  Future<void> _showNotification(
      {required String title, required String body}) async {
    _notifId++;
    await _localNotifications.show(
      id: _notifId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _noticeChannelId,
          _noticeChannelName,
          channelDescription: 'Notifications for new notices',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Start listening for new notices via onChildAdded.
  /// On first run it caches existing IDs; after that every new child triggers
  /// a notification.
  Future<void> startListening() async {
    stopListening();
    await _initNotifications();

    developer.log('Starting notice listener', name: 'NoticeService');

    final prefs = await SharedPreferences.getInstance();
    final seenIds =
        (prefs.getStringList(_seenNoticeIdsKey) ?? []).toSet();
    final bool isFirstRun = seenIds.isEmpty;

    // If first run, do a one-time read to seed the seen set
    if (isFirstRun) {
      final snapshot = await _noticesRef.get();
      if (snapshot.exists) {
        final allIds =
            Map<String, dynamic>.from(snapshot.value as Map).keys.toList();
        await prefs.setStringList(_seenNoticeIdsKey, allIds);
        developer.log(
          'First run: cached ${allIds.length} existing notice IDs',
          name: 'NoticeService',
        );
      }
    }

    // Now listen for every child added after this point
    _childAddedSubscription =
        _noticesRef.onChildAdded.listen((event) async {
      try {
        final id = event.snapshot.key;
        if (id == null) return;

        // Reload prefs to get the latest seen set
        await prefs.reload();
        final currentSeen =
            (prefs.getStringList(_seenNoticeIdsKey) ?? []).toSet();

        if (currentSeen.contains(id)) {
          // Already seen — skip (this happens for existing children on subscribe)
          return;
        }

        // It's a genuinely new notice — send notification
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final title = data['title'] ?? 'New Notice';
        final category = data['category'] ?? '';
        final important = data['important'] == true;

        await _showNotification(
          title: important ? '🔴 $title' : '📢 $title',
          body: category.isNotEmpty
              ? 'New $category notice posted'
              : 'A new notice has been posted',
        );

        developer.log('Notification sent for notice: $title',
            name: 'NoticeService');

        // Add to seen set
        currentSeen.add(id);
        await prefs.setStringList(
            _seenNoticeIdsKey, currentSeen.toList());
      } catch (e) {
        developer.log('Error in notice child listener: $e',
            name: 'NoticeService');
      }
    });
  }

  /// Provide a real-time stream of notices for the UI.
  Stream<List<Map<String, dynamic>>> noticesStream() {
    return _noticesRef.onValue.map((DatabaseEvent event) {
      if (!event.snapshot.exists) return <Map<String, dynamic>>[];

      final noticesMap =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      final List<Map<String, dynamic>> notices = [];

      noticesMap.forEach((key, value) {
        final notice = Map<String, dynamic>.from(value as Map);
        notices.add({
          'id': key,
          'title': notice['title'] ?? '',
          'category': notice['category'] ?? 'General',
          'content': notice['content'] ?? '',
          'date': notice['createdAt'] ?? '',
          'important': notice['important'] == true,
          'createdAt': notice['createdAt'] ?? '',
        });
      });

      // Sort by createdAt descending (newest first)
      notices.sort((a, b) =>
          (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      return notices;
    });
  }

  /// Stop listening for notices.
  void stopListening() {
    _childAddedSubscription?.cancel();
    _childAddedSubscription = null;
    developer.log('Stopped notice listener', name: 'NoticeService');
  }
}
