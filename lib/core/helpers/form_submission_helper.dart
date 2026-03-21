import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database_service.dart';
import '../queue_service.dart';

class FormSubmissionHelper {
  static Future<bool> submitForm({
    required String type,
    required String auid,
    required Map<String, dynamic> data,
  }) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);

      if (isOnline) {
        final database = DatabaseService.db;
        final ref = database.child(type).child(auid).push();
        
        await ref.set(data).timeout(const Duration(seconds: 5));
        return true;
      } else {
        // Offline - Add to Queue
        await QueueService.addToQueue(type, auid, data);
        return false;
      }
    } catch (e) {
      developer.log('Error submitting form $type: $e', name: 'FormSubmissionHelper');
      rethrow;
    }
  }
}
