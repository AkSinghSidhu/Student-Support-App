/// Application-wide constants.
class AppConstants {
  static const String appName = 'Student Support App';
  
  // SharedPreferences Keys
  static const String themeModeKey = 'theme_mode';
  static const String auidKey = 'logged_in_auid';
  static const String rememberMeKey = 'remember_me';
  static const String languageKey = 'language';
  static const String seenNoticeIdsKey = 'seen_notice_ids';
  static const String pendingQueueKey = 'pending_submissions_queue';

  // Hive Box Names
  static const String notificationsBoxKey = 'notifications';
  static const String attendanceCacheBox = 'attendance_cache';
  static const String noticesCacheBox = 'notices_cache';
  static const String feedbackCacheBox = 'feedback_cache';
  static const String complaintsCacheBox = 'complaints_cache';
  static const String syllabusCacheBox = 'syllabus_cache';
  static const String resourcesCacheBox = 'resources_cache';

  // API Endpoints
  static const String firebaseDbUrl = 'https://studentsupporttest-default-rtdb.asia-southeast1.firebasedatabase.app';

  // Constants
  static const double attendanceThreshold = 75.0;
}
