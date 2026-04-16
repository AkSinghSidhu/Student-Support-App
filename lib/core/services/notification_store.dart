import 'dart:convert';
import 'dart:developer' as developer;
import 'package:hive_flutter/hive_flutter.dart';
import '../app_constants.dart';

/// Hive-based local storage service for in-app notifications.
class NotificationStore {
  Box get _box => Hive.box(AppConstants.notificationsBoxKey);

  /// Add a new notification to the store.
  Future<void> addNotification({
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
      var list = _getList();
      list.insert(0, notification); // newest first
      // Keep only the 50 most recent notifications
      if (list.length > 50) {
        list = list.sublist(0, 50);
      }
      await _box.put('items', jsonEncode(list));
    } catch (e) {
      developer.log('Error adding notification: $e', name: 'NotificationStore');
    }
  }

  /// Get all notifications, newest first.
  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      return _getList();
    } catch (e) {
      developer.log('Error getting notifications: $e', name: 'NotificationStore');
      return [];
    }
  }

  /// Mark a single notification as read by its id.
  Future<void> markAsRead(String id) async {
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
  Future<void> markAllAsRead() async {
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
  Future<void> clearAll() async {
    try {
      await _box.put('items', jsonEncode([]));
    } catch (e) {
      developer.log('Error clearing notifications: $e', name: 'NotificationStore');
    }
  }

  /// Get the number of unread notifications.
  Future<int> getUnreadCount() async {
    try {
      final list = _getList();
      return list.where((item) => item['isRead'] == false).length;
    } catch (e) {
      developer.log('Error getting unread count: $e', name: 'NotificationStore');
      return 0;
    }
  }

  /// Internal helper to parse the stored JSON list.
  List<Map<String, dynamic>> _getList() {
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
