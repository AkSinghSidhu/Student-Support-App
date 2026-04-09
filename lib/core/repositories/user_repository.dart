import 'dart:developer' as developer;
import '../database_service.dart';
import '../di/service_locator.dart';
import '../../models/models.dart';

abstract class IUserRepository {
  Future<UserModel?> getUser(String auid);
}

class UserRepository implements IUserRepository {
  final DatabaseService _dbService;

  UserRepository({DatabaseService? dbService})
      : _dbService = dbService ?? sl<DatabaseService>();

  @override
  Future<UserModel?> getUser(String auid) async {
    try {
      final snapshot = await _dbService.db
          .child('users')
          .child(auid)
          .get();

      if (!snapshot.exists) return null;

      final raw = snapshot.value;
      if (raw is! Map) return null;

      return UserModel.fromJson(
        auid,
        Map<String, dynamic>.from(raw),
      );
    } catch (e) {
      developer.log('getUser error: $e', name: 'UserRepository');
      return null;
    }
  }
}
