import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:developer' as developer;

/// Service to handle offline caching of Firebase data using Hive.
class CacheService {
  static const _secureStorage = FlutterSecureStorage();
  static const _hiveEncryptionKeyName = 'hive_encryption_key';

  static Future<HiveAesCipher> _getEncryptionCipher() async {
    try {
      String? existingKey = await _secureStorage.read(
        key: _hiveEncryptionKeyName,
      );

      if (existingKey == null) {
        // Generate new 256-bit key
        final key = Hive.generateSecureKey();
        await _secureStorage.write(
          key: _hiveEncryptionKeyName,
          value: base64UrlEncode(key),
        );
        return HiveAesCipher(key);
      }

      return HiveAesCipher(base64Url.decode(existingKey));
    } catch (e) {
      developer.log(
        'Error getting Hive cipher: $e',
        name: 'CacheService',
      );
      rethrow;
    }
  }

  static const String _attendanceBox = 'attendance_cache';
  static const String _noticesBox = 'notices_cache';
  static const String _feedbackBox = 'feedback_cache';
  static const String _complaintsBox = 'complaints_cache';
  static const String _syllabusBox = 'syllabus_cache';
  static const String _resourcesBox = 'resources_cache';

  /// Initialize Hive and open all necessary boxes
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      final cipher = await _getEncryptionCipher();
      
      await Future.wait([
        Hive.openBox(_attendanceBox),
        Hive.openBox(_noticesBox),
        Hive.openBox(
          _feedbackBox,
          encryptionCipher: cipher,
        ),
        Hive.openBox(
          _complaintsBox,
          encryptionCipher: cipher,
        ),
        Hive.openBox(_syllabusBox),
        Hive.openBox(_resourcesBox),
      ]);
    } catch (e) {
      developer.log(
        'Hive init failed, clearing and retrying: $e',
        name: 'CacheService',
      );
      // Clear corrupted boxes and retry without encryption
      // This handles the case where boxes existed before
      // encryption was added
      await Hive.deleteBoxFromDisk(_feedbackBox);
      await Hive.deleteBoxFromDisk(_complaintsBox);

      await Future.wait([
        Hive.openBox(_attendanceBox),
        Hive.openBox(_noticesBox),
        Hive.openBox(_feedbackBox),
        Hive.openBox(_complaintsBox),
        Hive.openBox(_syllabusBox),
        Hive.openBox(_resourcesBox),
      ]);
    }
  }

  // --- Attendance Caching ---
  
  /// Cache attendance data for a specific user
  static Future<void> cacheAttendance(String auid, Map<String, dynamic> data) async {
    final box = Hive.box(_attendanceBox);
    await box.put(auid, jsonEncode(data));
  }
  
  /// Get cached attendance data for a specific user
  static Map<String, dynamic>? getAttendance(String auid) {
    try {
      final box = Hive.box(_attendanceBox);
      final dataString = box.get(auid);
      if (dataString != null) {
        return jsonDecode(dataString) as Map<String, dynamic>;
      }
    } catch (e) {
      developer.log('CacheService Error getting attendance: $e', name: 'CacheService');
    }
    return null;
  }

  // --- Notices Caching ---
  
  /// Cache a list of notices
  static Future<void> cacheNotices(List<Map<String, dynamic>> notices) async {
    final box = Hive.box(_noticesBox);
    final String encoded = jsonEncode(notices);
    await box.put('all_notices', encoded);
  }
  
  /// Get cached notices
  static List<Map<String, dynamic>>? getNotices() {
    try {
      final box = Hive.box(_noticesBox);
      final dataString = box.get('all_notices');
      if (dataString != null) {
        final List<dynamic> decoded = jsonDecode(dataString);
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      developer.log('CacheService Error getting notices: $e', name: 'CacheService');
    }
    return null;
  }

  // --- Feedback Caching ---
  
  /// Cache a single feedback submission to sync later
  static Future<void> cachePendingFeedback(Map<String, dynamic> feedback) async {
    final box = Hive.box(_feedbackBox);
    final pending = getPendingFeedback();
    pending.add(feedback);
    await box.put('pending_feedback', jsonEncode(pending));
  }
  
  /// Get all pending feedback submissions
  static List<Map<String, dynamic>> getPendingFeedback() {
    try {
      final box = Hive.box(_feedbackBox);
      final dataString = box.get('pending_feedback');
      if (dataString != null) {
        final List<dynamic> decoded = jsonDecode(dataString);
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      developer.log('CacheService Error getting pending feedback: $e', name: 'CacheService');
    }
    return [];
  }
  
  /// Clear pending feedback after successful sync
  static Future<void> clearPendingFeedback() async {
    final box = Hive.box(_feedbackBox);
    await box.delete('pending_feedback');
  }

  // --- Complaints Caching ---
  
  /// Cache a single complaint submission to sync later
  static Future<void> cachePendingComplaint(Map<String, dynamic> complaint) async {
    final box = Hive.box(_complaintsBox);
    final pending = getPendingComplaints();
    pending.add(complaint);
    await box.put('pending_complaints', jsonEncode(pending));
  }
  
  /// Get all pending complaint submissions
  static List<Map<String, dynamic>> getPendingComplaints() {
    try {
      final box = Hive.box(_complaintsBox);
      final dataString = box.get('pending_complaints');
      if (dataString != null) {
        final List<dynamic> decoded = jsonDecode(dataString);
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      developer.log('CacheService Error getting pending complaints: $e', name: 'CacheService');
    }
    return [];
  }
  
  /// Clear pending complaints after successful sync
  static Future<void> clearPendingComplaints() async {
    final box = Hive.box(_complaintsBox);
    await box.delete('pending_complaints');
  }

  // General clear all cache (e.g. on logout)
  static Future<void> clearAllUserCache() async {
    await Hive.box(_attendanceBox).clear();
    await Hive.box(_noticesBox).clear();
    await Hive.box(_feedbackBox).clear();
    await Hive.box(_complaintsBox).clear();
    await Hive.box(_syllabusBox).clear();
    await Hive.box(_resourcesBox).clear();
  }
}
