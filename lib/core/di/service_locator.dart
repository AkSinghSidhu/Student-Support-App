import 'package:get_it/get_it.dart';
import '../repositories/auth_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/notice_repository.dart';
import '../repositories/metadata_repository.dart';
import '../services/notification_service.dart';
import '../services/notice_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepository(),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepository(),
  );
  sl.registerLazySingleton<NoticeRepository>(
    () => NoticeRepository(),
  );
  sl.registerLazySingleton<MetadataRepository>(
    () => MetadataRepository(),
  );
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );
  sl.registerLazySingleton<NoticeService>(
    () => NoticeService(),
  );
}
