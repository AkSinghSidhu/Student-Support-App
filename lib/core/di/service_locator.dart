import 'package:get_it/get_it.dart';
import '../repositories/auth_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/notice_repository.dart';
import '../repositories/metadata_repository.dart';
import '../repositories/complaint_repository.dart';
import '../repositories/feedback_repository.dart';
import '../database_service.dart';
import '../services/cache_service.dart';
import '../queue_service.dart';
import '../helpers/form_submission_helper.dart';
import '../services/notification_service.dart';
import '../services/notification_store.dart';
import '../services/notice_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<DatabaseService>(
    () => DatabaseService(),
  );
  sl.registerLazySingleton<CacheService>(
    () => CacheService(),
  );
  sl.registerLazySingleton<QueueService>(
    () => QueueService(),
  );
  sl.registerLazySingleton<FormSubmissionHelper>(
    () => FormSubmissionHelper(),
  );
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
  sl.registerLazySingleton<ComplaintRepository>(
    () => ComplaintRepository(),
  );
  sl.registerLazySingleton<FeedbackRepository>(
    () => FeedbackRepository(),
  );
  sl.registerLazySingleton<NotificationStore>(
    () => NotificationStore(),
  );
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );
  sl.registerLazySingleton<NoticeService>(
    () => NoticeService(),
  );
}
