import 'dart:developer' as developer;
import '../di/service_locator.dart';
import '../database_service.dart';
import '../services/cache_service.dart';
import '../../models/models.dart';

abstract class IAttendanceRepository {
  Future<List<SubjectModel>> getSubjects(String auid);
}

class AttendanceRepository implements IAttendanceRepository {
  final DatabaseService _dbService;
  final CacheService _cacheService;

  AttendanceRepository({DatabaseService? dbService, CacheService? cacheService})
      : _dbService = dbService ?? sl<DatabaseService>(),
        _cacheService = cacheService ?? sl<CacheService>();

  @override
  Future<List<SubjectModel>> getSubjects(String auid) async {
    // Try cache first
    final cached = _cacheService.getAttendance(auid);
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
      final snapshot = await _dbService.db
          .child('attendance')
          .child(auid)
          .child('subjects')
          .get();

      if (!snapshot.exists) return [];

      final raw = snapshot.value;
      if (raw is! Map) return [];

      final data = Map<String, dynamic>.from(raw);
      await _cacheService.cacheAttendance(auid, data);

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
