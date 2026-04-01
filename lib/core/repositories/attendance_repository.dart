import 'dart:developer' as developer;
import '../database_service.dart';
import '../services/cache_service.dart';
import '../../models/models.dart';

class AttendanceRepository {
  Future<List<SubjectModel>> getSubjects(String auid) async {
    // Try cache first
    final cached = CacheService.getAttendance(auid);
    if (cached != null) {
      try {
        return cached.entries
            .where((e) => e.value is Map)
            .map((e) => SubjectModel.fromJson(
                  e.key,
                  Map<String, dynamic>.from(e.value as Map),
                ))
            .toList();
      } catch (e) {
        developer.log(
          'Cache parse error: $e',
          name: 'AttendanceRepository',
        );
      }
    }

    // Fetch from Firebase
    try {
      final snapshot = await DatabaseService.db
          .child('attendance')
          .child(auid)
          .child('subjects')
          .get();

      if (!snapshot.exists) return [];

      final raw = snapshot.value;
      if (raw is! Map) return [];

      final data = Map<String, dynamic>.from(raw);
      await CacheService.cacheAttendance(auid, data);

      return data.entries
          .where((e) => e.value is Map)
          .map((e) => SubjectModel.fromJson(
                e.key,
                Map<String, dynamic>.from(e.value as Map),
              ))
          .toList();
    } catch (e) {
      developer.log(
        'getSubjects error: $e',
        name: 'AttendanceRepository',
      );
      rethrow;
    }
  }
}
