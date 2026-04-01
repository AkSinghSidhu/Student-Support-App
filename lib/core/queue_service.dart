import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_constants.dart';
import 'database_service.dart';
import '../models/models.dart';

class QueueService {

  /// Save a new pending item to the queue
  static Future<void> addToQueue(String type, String auid, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final item = QueueItemModel(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        auid: auid,
        data: data,
        timestamp: DateTime.now(),
      );

      List<QueueItemModel> queue = await getPendingItems();
      queue.add(item);

      await prefs.setString(
        AppConstants.pendingQueueKey, 
        json.encode(queue.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      developer.log('QueueService Error adding to queue: $e', name: 'QueueService');
    }
  }

  /// Retrieve all pending items
  static Future<List<QueueItemModel>> getPendingItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? queueString = prefs.getString(AppConstants.pendingQueueKey);
      
      if (queueString == null || queueString.isEmpty) {
        return [];
      }
      
      final List<dynamic> decodedList = json.decode(queueString);
      return decodedList.map((item) => QueueItemModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      developer.log('QueueService Error getting pending items: $e', name: 'QueueService');
      return [];
    }
  }

  /// Delete an item from the queue after it successfully sends
  static Future<void> removeFromQueue(String localId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<QueueItemModel> queue = await getPendingItems();
      
      queue.removeWhere((item) => item.localId == localId);
      
      await prefs.setString(
        AppConstants.pendingQueueKey, 
        json.encode(queue.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      developer.log('QueueService Error removing from queue: $e', name: 'QueueService');
    }
  }

  /// Loop through all pending items and try to send them to Firebase
  static Future<void> retryAll() async {
    final List<QueueItemModel> queue = await getPendingItems();
    
    if (queue.isEmpty) return;

    final database = DatabaseService.db;

    for (final item in queue) {
      if (item.isExpired) {
        developer.log('Removing expired queue item: ${item.localId}', name: 'QueueService');
        await removeFromQueue(item.localId);
        continue;
      }

      try {
        if (item.type == 'complaint' || item.type == 'complaints') {
          final ref = database.child('complaints').child(item.auid).push();
          await ref.set(item.data);
        } else if (item.type == 'feedback') {
          final ref = database.child('feedback').child(item.auid).push();
          await ref.set(item.data);
        }
        
        // If set() succeeds, it's sent. Remove it from local queue.
        await removeFromQueue(item.localId);
      } catch (e) {
        // If it fails, keep it in the queue for the next retry
        developer.log('QueueService Error sending ${item.type} ${item.localId}: $e', name: 'QueueService');
      }
    }
  }
}
