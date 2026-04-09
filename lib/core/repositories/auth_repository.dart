import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import '../app_constants.dart';
import '../di/service_locator.dart';
import '../../models/models.dart';

abstract class IAuthRepository {
  Future<UserModel?> login(String auid, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<String?> getCurrentAuid();
}

class AuthRepository implements IAuthRepository {
  final DatabaseService _dbService;

  AuthRepository({DatabaseService? dbService})
      : _dbService = dbService ?? sl<DatabaseService>();

  @override
  Future<UserModel?> login(String auid, String password) async {
    try {
      final snapshot = await _dbService.db
          .child('users')
          .child(auid)
          .get();

      if (!snapshot.exists) return null;

      final raw = snapshot.value;
      if (raw is! Map) return null;

      final data = Map<String, dynamic>.from(raw);
      final storedPassword = data['password'] as String? ?? '';
      if (storedPassword != password) return null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.auidKey, auid);

      return UserModel.fromJson(auid, data);
    } catch (e) {
      developer.log('Login error: $e', name: 'AuthRepository');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      developer.log('Logout error: $e', name: 'AuthRepository');
      rethrow;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auid = prefs.getString(AppConstants.auidKey);
      return auid != null && auid.isNotEmpty;
    } catch (e) {
      developer.log('isLoggedIn error: $e', name: 'AuthRepository');
      return false;
    }
  }

  @override
  Future<String?> getCurrentAuid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.auidKey);
    } catch (e) {
      developer.log('getCurrentAuid error: $e', name: 'AuthRepository');
      return null;
    }
  }
}
