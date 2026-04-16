import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database_service.dart';
import '../queue_service.dart';
import '../di/service_locator.dart';

class FormSubmissionHelper {
  final DatabaseService _dbService;
  final QueueService _queueService;

  FormSubmissionHelper({DatabaseService? dbService, QueueService? queueService})
      : _dbService = dbService ?? sl<DatabaseService>(),
        _queueService = queueService ?? sl<QueueService>();

  static const List<String> _allowedTypes = ['complaints', 'feedback'];

  Future<bool> submitForm({
    required String type,
    required String auid,
    required Map<String, dynamic> data,
  }) async {
    if (!_allowedTypes.contains(type)) {
      developer.log(
        'Blocked invalid submission type: $type',
        name: 'FormSubmissionHelper',
      );
      throw ArgumentError('Invalid form type: $type');
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);

      if (isOnline) {
        final database = _dbService.db;
        final ref = database.child(type).child(auid).push();
        
        await ref.set(data).timeout(const Duration(seconds: 5));
        return true;
      } else {
        // Offline - Add to Queue
        await _queueService.addToQueue(type, auid, data);
        return false;
      }
    } catch (e) {
      developer.log('Error submitting form $type: $e', name: 'FormSubmissionHelper');
      rethrow;
    }
  }
}
