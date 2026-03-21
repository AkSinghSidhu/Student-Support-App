import 'dart:convert';
import 'dart:developer' as developer;
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-based local storage service for in-app notifications.
class NotificationStore {
  static const String _boxName = 'notifications';

  static Box get _box => Hive.box(_boxName);

  /// Add a new notification to the store.
  static Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final list = _getList();
      list.insert(0, notification); // newest first
      await _box.put('items', jsonEncode(list));
    } catch (e) {
      developer.log('Error adding notification: $e', name: 'NotificationStore');
    }
  }

  /// Get all notifications, newest first.
  static Future<List<Map<String, dynamic>>> getAll() async {
    try {
      return _getList();
    } catch (e) {
      developer.log('Error getting notifications: $e', name: 'NotificationStore');
      return [];
    }
  }

  /// Mark a single notification as read by its id.
  static Future<void> markAsRead(String id) async {
    try {
      final list = _getList();
      for (final item in list) {
        if (item['id'] == id) {
          item['isRead'] = true;
          break;
        }
      }
      await _box.put('items', jsonEncode(list));
    } catch (e) {
      developer.log('Error marking as read: $e', name: 'NotificationStore');
    }
  }

  /// Mark all notifications as read.
  static Future<void> markAllAsRead() async {
    try {
      final list = _getList();
      for (final item in list) {
        item['isRead'] = true;
      }
      await _box.put('items', jsonEncode(list));
    } catch (e) {
      developer.log('Error marking all as read: $e', name: 'NotificationStore');
    }
  }

  /// Clear all stored notifications.
  static Future<void> clearAll() async {
    try {
      await _box.put('items', jsonEncode([]));
    } catch (e) {
      developer.log('Error clearing notifications: $e', name: 'NotificationStore');
    }
  }

  /// Get the number of unread notifications.
  static Future<int> getUnreadCount() async {
    try {
      final list = _getList();
      return list.where((item) => item['isRead'] == false).length;
    } catch (e) {
      developer.log('Error getting unread count: $e', name: 'NotificationStore');
      return 0;
    }
  }

  /// Internal helper to parse the stored JSON list.
  static List<Map<String, dynamic>> _getList() {
    try {
      final raw = _box.get('items');
      if (raw == null) return [];
      final decoded = jsonDecode(raw as String);
      if (decoded is List) {
        return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      developer.log('Error parsing notification list: $e', name: 'NotificationStore');
      return [];
    }
  }
}
