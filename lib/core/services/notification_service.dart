import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle push notifications for attendance alerts.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const double alertThreshold = 75.0;
  int _notificationId = 0;

  /// Real-time listener subscription for attendance data
  StreamSubscription<DatabaseEvent>? _attendanceSubscription;

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
    String? token = await _firebaseMessaging.getToken();
    developer.log('FCM Token: $token', name: 'NotificationService');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    showNotification(
      title: message.notification?.title ?? 'Attendance Alert',
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

  /// Start a real-time listener on the user's attendance data.
  /// Fires a notification immediately if attendance is already low,
  /// and again whenever attendance data changes and drops below 75%.
  void startAttendanceListener(String auid) {
    // Cancel any existing listener first
    stopAttendanceListener();

    developer.log('Starting real-time attendance listener for $auid', name: 'NotificationService');

    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://studentsupporttest-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref();

    _attendanceSubscription = database
        .child('attendance')
        .child(auid)
        .child('subjects')
        .onValue
        .listen((DatabaseEvent event) async {
      try {
        final snapshot = event.snapshot;
        if (!snapshot.exists) return;

        final subjectsData = Map<String, dynamic>.from(snapshot.value as Map);
        final List<Map<String, dynamic>> subjects = [];
        int totalAttended = 0;
        int totalClasses = 0;

        subjectsData.forEach((key, value) {
          final subject = Map<String, dynamic>.from(value as Map);
          final attended = (subject['attended'] as num).toInt();
          final total = (subject['total'] as num).toInt();
          final percent = total > 0 ? (attended / total * 100) : 0.0;

          totalAttended += attended;
          totalClasses += total;

          subjects.add({
            'code': key,
            'name': subject['name'] ?? key,
            'attended': attended,
            'total': total,
            'percent': percent,
          });
        });

        final overall = totalClasses > 0 ? totalAttended / totalClasses * 100 : 100.0;

        // Get previously notified subjects to avoid duplicates
        final prefs = await SharedPreferences.getInstance();
        final lastNotifiedKey = 'last_notified_low_subjects_$auid';
        final previousLowSubjects = prefs.getStringList(lastNotifiedKey) ?? [];

        // Collect current low attendance subjects
        List<String> currentLowSubjects = [];
        for (var subject in subjects) {
          double percent = subject['percent'] as double;
          if (percent < alertThreshold) {
            currentLowSubjects.add(subject['name'] as String);
          }
        }

        // Find subjects that NEWLY dropped below threshold
        final newLowSubjects = currentLowSubjects
            .where((s) => !previousLowSubjects.contains(s))
            .toList();

        // Check if overall NEWLY dropped below threshold
        final wasOverallLow = prefs.getBool('was_overall_low_$auid') ?? false;
        final isOverallLow = overall < alertThreshold;

        if (isOverallLow && !wasOverallLow) {
          await showNotification(
            title: '⚠️ Low Overall Attendance',
            body: 'Your overall attendance is ${overall.toStringAsFixed(1)}%. Please attend more classes to reach 75%.',
          );
        }

        if (newLowSubjects.isNotEmpty) {
          String message = newLowSubjects.length == 1
              ? 'Your attendance in ${newLowSubjects.first} has dropped below 75%.'
              : 'Attendance dropped below 75% in: ${newLowSubjects.join(", ")}';

          await showNotification(
            title: '📚 Subject Attendance Alert',
            body: message,
          );
        }

        // Save current state for next comparison
        await prefs.setStringList(lastNotifiedKey, currentLowSubjects);
        await prefs.setBool('was_overall_low_$auid', isOverallLow);

        developer.log(
          'Attendance update: overall=${overall.toStringAsFixed(1)}%, '
          'low subjects=$currentLowSubjects, new alerts=$newLowSubjects',
          name: 'NotificationService',
        );
      } catch (e) {
        developer.log('Error in attendance listener: $e', name: 'NotificationService');
      }
    });
  }

  /// Stop the real-time attendance listener (e.g. on logout)
  void stopAttendanceListener() {
    _attendanceSubscription?.cancel();
    _attendanceSubscription = null;
    developer.log('Stopped attendance listener', name: 'NotificationService');
  }

  /// Check attendance from Firebase and send alerts at app startup
  /// Only sends notification once per day or when new subjects fall below threshold
  Future<void> checkAttendanceAtStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auid = prefs.getString('logged_in_auid');
      
      if (auid == null || auid.isEmpty) return;

      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://studentsupporttest-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref();

      final snapshot = await database.child('attendance').child(auid).child('subjects').get();

      if (!snapshot.exists) return;

      final subjectsData = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Map<String, dynamic>> subjects = [];
      int totalAttended = 0;
      int totalClasses = 0;

      subjectsData.forEach((key, value) {
        final subject = Map<String, dynamic>.from(value as Map);
        final attended = (subject['attended'] as num).toInt();
        final total = (subject['total'] as num).toInt();
        final percent = total > 0 ? (attended / total * 100) : 0.0;

        totalAttended += attended;
        totalClasses += total;

        subjects.add({
          'code': key,
          'name': subject['name'] ?? key,
          'attended': attended,
          'total': total,
          'percent': percent,
        });
      });

      final overall = totalClasses > 0 ? totalAttended / totalClasses * 100 : 100.0;

      // Get last notified subjects to avoid duplicate notifications
      final lastNotifiedKey = 'last_notified_low_subjects_$auid';
      final lastNotifiedDate = prefs.getString('last_notified_date_$auid') ?? '';
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      // Collect current low attendance subjects
      List<String> currentLowSubjects = [];
      for (var subject in subjects) {
        double percent = subject['percent'] as double;
        if (percent < alertThreshold) {
          currentLowSubjects.add(subject['name'] as String);
        }
      }

      // Check if overall is low
      bool overallIsLow = overall < alertThreshold;
      
      // Only send notifications if:
      // 1. It's a new day, OR
      // 2. There are new subjects below threshold
      final previousLowSubjects = prefs.getStringList(lastNotifiedKey) ?? [];
      final newLowSubjects = currentLowSubjects.where((s) => !previousLowSubjects.contains(s)).toList();
      final isNewDay = lastNotifiedDate != today;

      if (overallIsLow && (isNewDay || previousLowSubjects.isEmpty)) {
        await showNotification(
          title: '⚠️ Low Overall Attendance',
          body: 'Your overall attendance is ${overall.toStringAsFixed(1)}%. Please attend more classes to reach 75%.',
        );
      }

      if (newLowSubjects.isNotEmpty || (isNewDay && currentLowSubjects.isNotEmpty)) {
        final subjectsToNotify = isNewDay ? currentLowSubjects : newLowSubjects;
        String message = subjectsToNotify.length == 1
            ? 'Your attendance in ${subjectsToNotify.first} is below 75%.'
            : 'Low attendance in: ${subjectsToNotify.join(", ")}';
        
        await showNotification(
          title: '📚 Subject Attendance Alert',
          body: message,
        );
      }

      // Save current state
      await prefs.setStringList(lastNotifiedKey, currentLowSubjects);
      await prefs.setString('last_notified_date_$auid', today);
      await prefs.setBool('was_overall_low_$auid', overallIsLow);

    } catch (e) {
      developer.log('Error checking attendance: $e', name: 'NotificationService');
    }
  }

  /// Legacy method - kept for compatibility but not recommended to use from UI
  Future<void> checkAndSendAttendanceAlerts({
    required double overallAttendance,
    required List<Map<String, dynamic>> subjects,
  }) async {
    // This method is deprecated - use checkAttendanceAtStartup instead
    // Keeping for backwards compatibility
  }
}
