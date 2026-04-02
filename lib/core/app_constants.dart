import 'config/app_config.dart';

/// Application-wide constants.
class AppConstants {
  static AppConfig get config => AppConfig.current;

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
  static String get firebaseDbUrl => config.firebaseDbUrl;

  // Constants
  static const double attendanceThreshold = 75.0;

  // UI Strings - General
  static const String textLogOut = 'Log Out';
  static const String textProfileComingSoon = 'Profile page coming soon';
  static const String textLoginFailed = 'Login Failed';
  static const String textLoading = 'Loading...';

  // UI Strings - Drawer / Navigation
  static const String navHome = 'Home';
  static const String navSyllabus = 'Syllabus';
  static const String navResources = 'Resources';
  static const String navAttendance = 'Attendance';
  static const String navNotices = 'Notices';
  static const String navFeedback = 'Feedback / Contact';
  static const String navComplaints = 'Complaints';
  static const String navMyHistory = 'My History';
  static const String navSettings = 'Settings';
  static const String navSupport = 'Support';

  // UI Strings - Login
  static const String loginWelcomeTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to continue your journey';
  static const String loginAuidLabel = 'AUID Number';
  static const String loginAuidHint = 'Enter your 9-digit AUID';
  static const String loginAuidEmpty = 'Please enter your AUID';
  static const String loginAuidLengthError = 'AUID must be exactly 9 digits';
  static const String loginPasswordLabel = 'Password';
  static const String loginPasswordHint = 'Enter your password';
  static const String loginPasswordEmpty = 'Please enter your password';
  static const String loginPasswordLengthError = 'Password must be at least 6 characters';
  static const String loginRememberMe = 'Remember me';
  static const String loginForgotPasswordBtn = 'Forgot Password?';
  static const String loginSignInBtn = 'Sign In';
  static const String loginErrorInvalid = 'Invalid AUID or password.';
  static const String loginErrorPermission = 'Access denied. Contact admin to check Firebase rules.';
  static const String loginErrorNetwork = 'No internet connection. Please try again.';
  static const String loginErrorTimeout = 'Connection timed out. Please try again.';
  static const String loginErrorAdminContact = 'Contact admin to reset your password.';

  // UI Strings - History
  static const String statusPending = 'pending';
  static const String statusResolved = 'resolved';
  static const String statusRejected = 'rejected';

  // UI Strings - Tabs
  static const String tabComplaints = 'Complaints';
  static const String tabFeedback = 'Feedback';
  static const String tabBooks = 'Books';
  static const String tabNotes = 'Notes';
  static const String tabPyqs = 'PYQs';

  // UI Strings - Search
  static const String searchBooks = 'Search books...';
  static const String searchNotes = 'Search notes...';
  static const String searchPyqs = 'Search PYQs...';

  // Fallback Mappings
  static const Map<String, List<String>> defaultDepartmentTeachers = {
    'Computer Science': [
      'Dr. Alan Turing',
      'Prof. Ada Lovelace',
      'Dr. Grace Hopper',
      'Prof. Donald Knuth',
    ],
    'Electronics': [
      'Dr. Nikola Tesla',
      'Prof. Heinrich Hertz',
      'Dr. John Bardeen',
      'Prof. Thomas Edison',
    ],
    'Mechanical': [
      'Dr. Isaac Newton',
      'Prof. James Watt',
      'Dr. Rudolf Diesel',
      'Prof. Nikolaus Otto',
    ],
    'Civil': [
      'Dr. John Smeaton',
      'Prof. Gustave Eiffel',
      'Dr. Karl Terzaghi',
    ],
  };
}
