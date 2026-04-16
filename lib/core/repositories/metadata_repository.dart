import 'dart:developer' as developer;
import '../di/service_locator.dart';
import '../database_service.dart';
import '../services/cache_service.dart';
import '../app_constants.dart';

abstract class IMetadataRepository {
  Future<Map<String, List<String>>> getDepartmentTeachers();
}

class MetadataRepository implements IMetadataRepository {
  final DatabaseService _dbService;
  final CacheService _cacheService;

  MetadataRepository({DatabaseService? dbService, CacheService? cacheService})
      : _dbService = dbService ?? sl<DatabaseService>(),
        _cacheService = cacheService ?? sl<CacheService>();
  /// Fetches the department to teacher mapping from Firebase RTDB.
  /// Uses a robust fallback chain: Firebase -> Hive (Cache) -> AppConstants (Default).
  @override
  Future<Map<String, List<String>>> getDepartmentTeachers() async {
    try {
      final snapshot = await _dbService.db
          .child('config')
          .child('departmentTeachers')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final rawData = snapshot.value;
        if (rawData is Map) {
          final mappedData = <String, List<String>>{};
          rawData.forEach((key, value) {
            if (value is List) {
              mappedData[key.toString()] =
                  value.map((e) => e.toString()).toList();
            }
          });

          if (mappedData.isNotEmpty) {
            // Cache the newly fetched data
            await _cacheService.cacheDepartmentTeachers(mappedData);
            return mappedData;
          }
        }
      }
    } catch (e) {
      developer.log('Firebase fetch failed for departmentTeachers: $e',
          name: 'MetadataRepository');
    }

    // Fallback 1: Try to load from Hive cache
    final cachedData = _cacheService.getCachedDepartmentTeachers();
    if (cachedData != null && cachedData.isNotEmpty) {
      developer.log('Serving departmentTeachers from Cache',
          name: 'MetadataRepository');
      return cachedData;
    }

    // Fallback 2: Return hardcoded defaults
    developer.log('Serving departmentTeachers from AppConstants fallback',
        name: 'MetadataRepository');
    return AppConstants.defaultDepartmentTeachers;
  }
}
