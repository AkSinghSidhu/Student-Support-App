// ═══════════════════════════════════════════════════════════════════════════════
// BACKGROUND ATTENDANCE SERVICE — SCHEDULED DAILY CHECK
// ═══════════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
//   Check attendance once per day around 6:00 PM and send a local notification
//   if any subject is below 75%. This replaces the old persistent .listen()
//   approach that kept an open Firebase socket 24/7.
//
// HOW IT WORKS:
//   1. A Timer.periodic fires every 30 minutes.
//   2. On each tick it checks:
//      a) Is it 6 PM or later?       → No  → sleep until next tick.
//      b) Already notified today?     → Yes → sleep until next tick.
//   3. If both gates pass, it waits a random 0–1800 second delay (prevents
//      all 5 000 students from hitting Firebase at the exact same second).
//   4. It does a SINGLE .get() call to Firebase to fetch this student's
//      attendance data, then immediately releases the connection.
//   5. It calculates per-subject percentages and fires a local notification
//      listing any subjects below 75%.
//   6. It saves today's date so the check won't run again until tomorrow.
//
// FIREBASE USAGE:
//   • Zero persistent connections.  Only one short-lived .get() per day.
//   • Safe for 5 000+ concurrent users on the Firebase free plan.
//
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../app_constants.dart';

// ── Notification channel IDs ────────────────────────────────────────────────
// Service channel (silent, low importance) — for the persistent foreground
// notification required by Android to keep the service alive.
const String serviceChannelId = 'attendance_service_channel';
const String serviceChannelName = 'Background Service';
const String serviceChannelDesc = 'Keeps the app running to monitor attendance';

// Alert channel (high importance, sound) — for the actual attendance alerts.
const String alertChannelId = 'attendance_alerts';
const String alertChannelName = 'Attendance Alerts';
const String alertChannelDesc = 'Notifications for low attendance warnings';

// ── Constants ───────────────────────────────────────────────────────────────
const double _alertThreshold = 75.0;
const int _checkHour = 18; // 6:00 PM in 24-hour format
const int _timerIntervalMinutes = 30;
const int _maxRandomDelaySeconds = 1800; // 30 minutes spread

// SharedPreferences key for the date of the last successful notification check.
const String _notifSentDateKey = 'notification_sent_date';

// ═════════════════════════════════════════════════════════════════════════════
// ENTRY POINT — runs in the background isolate
// ═════════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // ── Initialize Firebase ─────────────────────────────────────────────────
  await Firebase.initializeApp();

  // ── Initialize local notifications ──────────────────────────────────────
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  const serviceChannel = AndroidNotificationChannel(
    serviceChannelId,
    serviceChannelName,
    description: serviceChannelDesc,
    importance: Importance.low,
    showBadge: false,
  );

  const alertChannel = AndroidNotificationChannel(
    alertChannelId,
    alertChannelName,
    description: alertChannelDesc,
    importance: Importance.high,
    playSound: true,
  );

  final androidImpl = notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidImpl?.createNotificationChannel(serviceChannel);
  await androidImpl?.createNotificationChannel(alertChannel);

  await notificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // ── Service lifecycle handlers ──────────────────────────────────────────
  service.on('stopService').listen((event) => service.stopSelf());

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) => service.setAsForegroundService());
    service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
  }

  // ── Show the persistent (silent) foreground notification ────────────────
  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      notificationsPlugin.show(
        id: 888,
        title: 'Attendance Monitor',
        body: 'Will check attendance daily at 6 PM',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            serviceChannelId,
            serviceChannelName,
            icon: '@mipmap/ic_launcher',
            ongoing: true,
            importance: Importance.low,
            priority: Priority.low,
            autoCancel: false,
            showWhen: false,
          ),
        ),
      );
    }
  }

  // ── Validate logged-in user ─────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  final auid = prefs.getString('logged_in_auid');

  if (auid == null || auid.isEmpty) {
    developer.log(
      'No user logged in — background service stopping.',
      name: 'BackgroundService',
    );
    service.stopSelf();
    return;
  }

  developer.log(
    'Background service started for $auid. '
    'Timer will tick every $_timerIntervalMinutes minutes.',
    name: 'BackgroundService',
  );

  // ── Run one immediate check, then start the periodic timer ──────────────
  _scheduledCheck(auid, prefs, notificationsPlugin, service);

  Timer.periodic(
    const Duration(minutes: _timerIntervalMinutes),
    (_) => _scheduledCheck(auid, prefs, notificationsPlugin, service),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// CORE CHECK — called every 30 minutes by the timer
// ═════════════════════════════════════════════════════════════════════════════

Future<void> _scheduledCheck(
  String auid,
  SharedPreferences prefs,
  FlutterLocalNotificationsPlugin notificationsPlugin,
  ServiceInstance service,
) async {
  try {
    // ── STEP 2: Time gate — only proceed at or after 6 PM ─────────────────
    final now = DateTime.now();
    if (now.hour < _checkHour) {
      developer.log(
        'Before $_checkHour:00 (currently ${now.hour}:${now.minute}) — skipping.',
        name: 'BackgroundService',
      );
      return;
    }

    // ── STEP 3: Already-done gate — skip if we already checked today ──────
    await prefs.reload(); // get latest from disk
    final lastSentDate = prefs.getString(_notifSentDateKey) ?? '';
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (lastSentDate == today) {
      developer.log(
        'Already checked today ($today) — skipping.',
        name: 'BackgroundService',
      );
      return;
    }

    // ── STEP 4: Random delay (thundering herd prevention) ─────────────────
    final randomDelay = Random().nextInt(_maxRandomDelaySeconds);
    developer.log(
      'Passed time gates. Waiting ${randomDelay}s before fetching…',
      name: 'BackgroundService',
    );
    await Future.delayed(Duration(seconds: randomDelay));

    // Double-check after the delay — another tick may have completed while
    // we were sleeping.
    await prefs.reload();
    final recheckDate = prefs.getString(_notifSentDateKey) ?? '';
    if (recheckDate == today) {
      developer.log(
        'Another tick already completed today — skipping.',
        name: 'BackgroundService',
      );
      return;
    }

    // ── STEP 5: Single .get() fetch from Firebase ─────────────────────────
    developer.log('Fetching attendance for $auid…', name: 'BackgroundService');

    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConstants.firebaseDbUrl,
    ).ref();

    final snapshot = await database
        .child('attendance')
        .child(auid)
        .child('subjects')
        .get();

    if (!snapshot.exists || snapshot.value is! Map) {
      developer.log(
        'No attendance data found — marking today as done.',
        name: 'BackgroundService',
      );
      await prefs.setString(_notifSentDateKey, today);
      return;
    }

    // ── STEP 6: Calculate per-subject percentages ─────────────────────────
    final subjectsData = Map<String, dynamic>.from(snapshot.value as Map);
    final List<String> lowSubjects = [];
    int totalAttended = 0;
    int totalClasses = 0;

    subjectsData.forEach((key, value) {
      if (value is! Map) return;
      final subject = Map<String, dynamic>.from(value);
      final attended = (subject['attended'] as num).toInt();
      final total = (subject['total'] as num).toInt();
      final percent = total > 0 ? (attended / total * 100) : 100.0;

      totalAttended += attended;
      totalClasses += total;

      if (percent < _alertThreshold) {
        final name = subject['name'] ?? key;
        lowSubjects.add('$name (${percent.toStringAsFixed(0)}%)');
      }
    });

    final overall = totalClasses > 0
        ? (totalAttended / totalClasses * 100)
        : 100.0;

    // ── STEP 7: Send notification if needed ───────────────────────────────
    if (lowSubjects.isNotEmpty) {
      final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      String title;
      String body;

      if (overall < _alertThreshold) {
        title = '⚠️ Low Attendance Alert';
        body = 'Overall: ${overall.toStringAsFixed(1)}%\n'
            '${lowSubjects.join(", ")} below 75%';
      } else {
        title = '📚 Subject Attendance Alert';
        body = 'Low attendance in: ${lowSubjects.join(", ")}';
      }

      await notificationsPlugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            alertChannelId,
            alertChannelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
          ),
        ),
      );

      developer.log(
        'Notification sent: $title — $body',
        name: 'BackgroundService',
      );
    } else {
      developer.log(
        'All subjects above 75% (overall ${overall.toStringAsFixed(1)}%) '
        '— no notification needed.',
        name: 'BackgroundService',
      );
    }

    // ── Update persistent service notification with today's stats ────────
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        notificationsPlugin.show(
          id: 888,
          title: 'Attendance Monitor',
          body: 'Last check: ${now.hour}:${now.minute.toString().padLeft(2, '0')} '
              '| Overall: ${overall.toStringAsFixed(1)}% '
              '| Low: ${lowSubjects.length}',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              serviceChannelId,
              serviceChannelName,
              icon: '@mipmap/ic_launcher',
              ongoing: true,
              importance: Importance.low,
              priority: Priority.low,
              showWhen: false,
            ),
          ),
        );
      }
    }

    // ── STEP 8: Mark today as done ────────────────────────────────────────
    await prefs.setString(_notifSentDateKey, today);

    developer.log(
      'Attendance check complete for $today. Sleeping until tomorrow.',
      name: 'BackgroundService',
    );
  } catch (e) {
    // ── STEP 9: Error handling — log and sleep, never crash ──────────────
    developer.log(
      'Error during scheduled attendance check: $e',
      name: 'BackgroundService',
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SERVICE INITIALIZER — called once from main.dart
// ═════════════════════════════════════════════════════════════════════════════

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Pre-create the notification channel in the main isolate so it exists
  // before the background isolate tries to promote to foreground.
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  const serviceChannel = AndroidNotificationChannel(
    serviceChannelId,
    serviceChannelName,
    description: serviceChannelDesc,
    importance: Importance.low,
    showBadge: false,
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(serviceChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: serviceChannelId,
      initialNotificationTitle: 'Attendance Monitor',
      initialNotificationContent: 'Will check attendance daily at 6 PM',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: (ServiceInstance service) async {
        return true;
      },
    ),
  );

  service.startService();
}
