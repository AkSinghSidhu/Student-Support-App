import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

// Channel for the persistent foreground service notification (Silent/Low Importance)
const String serviceChannelId = 'attendance_service_channel';
const String serviceChannelName = 'Background Service';
const String serviceChannelDesc = 'Keeps the app running to monitor attendance';

// Channel for the actual alerts (High Importance/Sound)
const String alertChannelId = 'attendance_alerts';
const String alertChannelName = 'Attendance Alerts';
const String alertChannelDesc = 'Notifications for low attendance warnings';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter_background_service:4.5.0+1
  DartPluginRegistrant.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Local Notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Create Service Channel (Low Importance)
  const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
    serviceChannelId,
    serviceChannelName,
    description: serviceChannelDesc,
    importance: Importance.low, // Silent, minimized
    showBadge: false,
  );

  // Create Alert Channel (High Importance)
  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    alertChannelId,
    alertChannelName,
    description: alertChannelDesc,
    importance: Importance.high, // Pop-up, sound
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(serviceChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertChannel);

  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // Bring to foreground
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Check if we need to show the foreground notification
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  
  // Show initial notification to indicate service is running (on Low importance channel)
  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      flutterLocalNotificationsPlugin.show(
        id: 888,
        title: 'Attendance Monitor',
        body: 'Running in background (Tap to open)',
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

  // Get user ID
  final prefs = await SharedPreferences.getInstance();
  final auid = prefs.getString('logged_in_auid');

  if (auid == null || auid.isEmpty) {
    developer.log('No user logged in, background service stopping.', name: 'BackgroundService');
    service.stopSelf();
    return;
  }

  developer.log('Starting background attendance listener for $auid', name: 'BackgroundService');

  // Start listening to Firebase
  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://studentsupporttest-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  // Store the last modified time to prevent duplicate alerts on service restart
  
  database
      .child('attendance')
      .child(auid)
      .child('subjects')
      .onValue
      .listen((event) async {
    try {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return;

      final subjectsData = Map<String, dynamic>.from(snapshot.value as Map);
      int totalAttended = 0;
      int totalClasses = 0;
      List<String> currentLowSubjects = [];
      const double alertThreshold = 75.0;

      subjectsData.forEach((key, value) {
        final subject = Map<String, dynamic>.from(value as Map);
        final attended = (subject['attended'] as num).toInt();
        final total = (subject['total'] as num).toInt();
        final percent = total > 0 ? (attended / total * 100) : 0.0;

        totalAttended += attended;
        totalClasses += total;

        if (percent < alertThreshold) {
          currentLowSubjects.add(subject['name'] ?? key);
        }
      });

      final overall = totalClasses > 0 ? totalAttended / totalClasses * 100 : 100.0;

      // Reload prefs to get the absolute latest state
      await prefs.reload();
      final lastNotifiedKey = 'last_notified_low_subjects_$auid';
      final previousLowSubjects = prefs.getStringList(lastNotifiedKey) ?? [];
      final wasOverallLow = prefs.getBool('was_overall_low_$auid') ?? false;
      final isOverallLow = overall < alertThreshold;

      // Logic to determine if we should notify
      // 1. Overall dropped below 75%
      // 2. New subject dropped below 75%
      
      bool shouldNotify = false;
      String title = '';
      String body = '';

      if (isOverallLow && !wasOverallLow) {
        shouldNotify = true;
        title = '⚠️ Low Overall Attendance';
        body = 'Your overall attendance is ${overall.toStringAsFixed(1)}%.';
      }

      final newLowSubjects = currentLowSubjects
          .where((s) => !previousLowSubjects.contains(s))
          .toList();

      if (newLowSubjects.isNotEmpty) {
        shouldNotify = true;
        // If we already have a title (overall low), append
        if (title.isNotEmpty) {
           body += '\nAlso, ${newLowSubjects.join(", ")} dropped below 75%.';
        } else {
           title = '📚 Subject Attendance Alert';
           body = newLowSubjects.length == 1
              ? '${newLowSubjects.first} dropped below 75%.'
              : 'Attendance dropped in: ${newLowSubjects.join(", ")}';
        }
      }

      // Update the persistent "Service" notification (ID 888) to show live stats
      // This makes the persistent notification useful instead of just annoying
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          flutterLocalNotificationsPlugin.show(
            id: 888,
            title: 'Attendance Monitor Active',
            body: 'Overall: ${overall.toStringAsFixed(1)}% | Low Subjects: ${currentLowSubjects.length}',
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

      // Send Actual Alert on High Importance Channel
      if (shouldNotify) {
         int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
         
         await flutterLocalNotificationsPlugin.show(
          id: notificationId,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              alertChannelId,
              alertChannelName,
              importance: Importance.high, // MUST be high to pop up
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
            ),
          ),
        );
      }

      // Update state
      if (shouldNotify || currentLowSubjects.length != previousLowSubjects.length) {
         await prefs.setStringList(lastNotifiedKey, currentLowSubjects);
         await prefs.setBool('was_overall_low_$auid', isOverallLow);
      }
      
    } catch (e) {
      developer.log('Error in background listener: $e', name: 'BackgroundService');
    }
  });
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Create the notification channel in the main isolate to ensure it exists
  // before the background service tries to use it for foreground promotion.
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
    serviceChannelId,
    serviceChannelName,
    description: serviceChannelDesc,
    importance: Importance.low,
    showBadge: false,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(serviceChannel);
  
  // Configure the service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: serviceChannelId, // Use the SILENT channel for the service itself
      initialNotificationTitle: 'Attendance Monitor',
      initialNotificationContent: 'Running in background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: (ServiceInstance service) async {
        // iOS background fetch is limited, this is a best-effort
        return true;
      },
    ),
  );
  
  service.startService();
}
