import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_support_app/core/services/notification_service.dart';
import 'package:student_support_app/core/app_constants.dart';
import 'package:student_support_app/core/services/notification_store.dart';

const String attendanceTask = "checkAttendanceTask";

// ═════════════════════════════════════════════════════════════════════════════
// ENTRY POINT — runs in the background isolate
// ═════════════════════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auid = prefs.getString(AppConstants.auidKey);
      
      if (auid == null || auid.isEmpty) {
        return Future.value(true);
      }

      // Fetch attendance via REST API
      final url = Uri.parse('${AppConstants.firebaseDbUrl}/attendance/$auid/subjects.json');
      final response = await http.get(url);

      if (response.statusCode != 200 || response.body == 'null') {
        return Future.value(true); // No data, exit cleanly
      }

      final Map<String, dynamic> subjectsData = json.decode(response.body);
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

        if (percent < 75.0) {
          final name = subject['name'] ?? key;
          lowSubjects.add('$name (${percent.toStringAsFixed(0)}%)');
        }
      });

      final overall = totalClasses > 0 ? (totalAttended / totalClasses * 100) : 100.0;

      if (lowSubjects.isNotEmpty) {
        // Initialize NotificationService since this is a new isolate
        await NotificationService().initialize();

        String title;
        String body;

        if (overall < 75.0) {
          title = '⚠️ Low Attendance Alert';
          body = 'Overall: ${overall.toStringAsFixed(1)}%\n${lowSubjects.join(", ")} below 75%';
        } else {
          title = '📚 Subject Attendance Alert';
          body = 'Low attendance in: ${lowSubjects.join(", ")}';
        }

        await NotificationService().showNotification(title: title, body: body);

        // Store in-app notification
        await NotificationStore.addNotification(
          title: title,
          body: body,
          type: 'attendance',
        );
      }

    } catch (e) {
      // Log error internally, but return true so it can retry later
      developer.log("WorkManager check failed: $e", name: 'BackgroundService');
    }
    
    return Future.value(true);
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS & INITIALIZATION
// ═════════════════════════════════════════════════════════════════════════════

/// Helper function to calculate time until the next 6:00 PM
Duration _timeUntilNextSixPM() {
  final now = DateTime.now();
  DateTime nextSixPM = DateTime(now.year, now.month, now.day, 18, 0, 0);

  if (now.isAfter(nextSixPM)) {
    // If it's already past 6 PM today, schedule for tomorrow
    nextSixPM = nextSixPM.add(const Duration(days: 1));
  }

  return nextSixPM.difference(now);
}

/// Initialize Workmanager and schedule periodic task
void initializeBackgroundService() {
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  scheduleAttendanceCheck();
}

/// Schedule the periodic attendance check
void scheduleAttendanceCheck() {
  final initialDelay = _timeUntilNextSixPM();

  Workmanager().registerPeriodicTask(
    "1", // Unique ID
    attendanceTask,
    frequency: const Duration(hours: 24),
    initialDelay: initialDelay,
    constraints: Constraints(
      networkType: NetworkType.connected, // Only run if internet is available
    ),
  );
}

/// Call this on logout to cancel the attendance check
void cancelAttendanceCheck() {
  Workmanager().cancelByUniqueName("1");
}
