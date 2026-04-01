import 'dart:developer' as developer;
import '../database_service.dart';
import '../../models/models.dart';

class UserRepository {
  Future<UserModel?> getUser(String auid) async {
    try {
      final snapshot = await DatabaseService.db
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
