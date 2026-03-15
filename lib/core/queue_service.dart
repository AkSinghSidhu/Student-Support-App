import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class QueueService {
  static const String _queueKey = 'pending_submissions_queue';

  /// Save a new pending item to the queue
  static Future<void> addToQueue(String type, String auid, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate unique local ID
      final String localId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final Map<String, dynamic> newItem = {
        'localId': localId,
        'type': type,
        'auid': auid,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      List<Map<String, dynamic>> queue = await getPendingItems();
      queue.add(newItem);

      await prefs.setString(_queueKey, json.encode(queue));
    } catch (e) {
      developer.log('QueueService Error adding to queue: $e', name: 'QueueService');
    }
  }

  /// Retrieve all pending items
  static Future<List<Map<String, dynamic>>> getPendingItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? queueString = prefs.getString(_queueKey);
      
      if (queueString == null || queueString.isEmpty) {
        return [];
      }
      
      final List<dynamic> decodedList = json.decode(queueString);
      return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      developer.log('QueueService Error getting pending items: $e', name: 'QueueService');
      return [];
    }
  }

  /// Delete an item from the queue after it successfully sends
  static Future<void> removeFromQueue(String localId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> queue = await getPendingItems();
      
      queue.removeWhere((item) => item['localId'] == localId);
      
      await prefs.setString(_queueKey, json.encode(queue));
    } catch (e) {
      developer.log('QueueService Error removing from queue: $e', name: 'QueueService');
    }
  }

  /// Loop through all pending items and try to send them to Firebase
  static Future<void> retryAll() async {
    final List<Map<String, dynamic>> queue = await getPendingItems();
    
    if (queue.isEmpty) return;

    final database = DatabaseService.db;

    for (final item in queue) {
      final String type = item['type'];
      final String auid = item['auid'];
      final String localId = item['localId'];
      final Map<String, dynamic> data = item['data'];

      try {
        if (type == 'complaint' || type == 'complaints') {
          final ref = database.child('complaints').child(auid).push();
          await ref.set(data);
        } else if (type == 'feedback') {
          final ref = database.child('feedback').child(auid).push();
          await ref.set(data);
        }
        
        // If set() succeeds, it's sent. Remove it from local queue.
        await removeFromQueue(localId);
      } catch (e) {
        // If it fails, keep it in the queue for the next retry
        developer.log('QueueService Error sending $type $localId: $e', name: 'QueueService');
      }
    }
  }
}
