import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/utils/responsive_layout.dart';
import '../widgets/feature_tile.dart';
import '../../../core/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/services/notification_store.dart';
import '../../../core/di/service_locator.dart';
import '../../notifications/notifications_page.dart';
import '../../../models/feature_data.dart';
import '../../../core/repositories/user_repository.dart';

/// Home page with animated feature grid after login.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _gridController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // Student data
  String _studentName = 'Student';
  String _studentClass = '';
  String _studentAuid = '';
  int _unreadCount = 0;

  final List<FeatureData> _features = [
    FeatureData(
      title: AppConstants.tabFeedback,
      subtitle: 'Share your thoughts',
      icon: Icons.feedback_outlined,
      color: AppColors.feedbackColor,
      route: AppRoutes.feedback,
    ),
    FeatureData(
      title: AppConstants.tabComplaints,
      subtitle: 'Report issues',
      icon: Icons.report_problem_outlined,
      color: AppColors.complaintColor,
      route: AppRoutes.complaint,
    ),
    FeatureData(
      title: AppConstants.navSyllabus,
      subtitle: 'Course structure',
      icon: Icons.menu_book_outlined,
      color: AppColors.syllabusColor,
      route: AppRoutes.syllabus,
    ),
    FeatureData(
      title: AppConstants.navResources,
      subtitle: 'Books, Notes & PYQs',
      icon: Icons.library_books_outlined,
      color: AppColors.resourcesColor,
      route: AppRoutes.resources,
    ),
    FeatureData(
      title: AppConstants.navAttendance,
      subtitle: 'Track & alerts',
      icon: Icons.calendar_today_outlined,
      color: AppColors.attendanceColor,
      route: AppRoutes.attendance,
    ),
    FeatureData(
      title: AppConstants.navNotices,
      subtitle: 'Announcements',
      icon: Icons.campaign_outlined,
      color: AppColors.noticesColor,
      route: AppRoutes.notices,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Load student data from Firebase
    _loadStudentData();

    // Load unread notification count
    _refreshUnreadCount();

    // Header animation
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Grid animation
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Start animations
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _gridController.forward();
    });
  }

  final _userRepo = sl<UserRepository>();

  Future<void> _loadStudentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auid = prefs.getString(AppConstants.auidKey);

      if (auid != null && auid.isNotEmpty) {
        final user = await _userRepo.getUser(auid);
        
        if (user != null && mounted) {
          setState(() {
            _studentName = user.name.isNotEmpty ? user.name : 'Student';
            _studentClass = user.department;
            _studentAuid = auid;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Handle error silently, keep default values
    }
  }

  Future<void> _refreshUnreadCount() async {
    final count = await sl<NotificationStore>().getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }


  @override
  void dispose() {
    _headerController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context, isDarkMode);
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      drawer: AppDrawer(
        studentName: _studentName,
        studentAuid: _studentAuid,
        studentDepartment: _studentClass,
      ),
      drawerEnableOpenDragGesture: true,
      body: Column(
        children: [
          // Header section
          _buildHeader(context, isDarkMode),
          // Features grid
          Expanded(
            child: _buildFeaturesGrid(context, isDarkMode),
          ),
        ],
      ),
    ),
    );
  }

  Future<bool> _showExitDialog(
    BuildContext context,
    bool isDarkMode,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Exit App',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        content: Text(
          'Are you sure you want to exit?',
          style: TextStyle(
            color: isDarkMode
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Exit',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardBackgroundDark : null,
            gradient: isDarkMode ? null : AppColors.primaryGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with hamburger, avatar and notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Hamburger menu icon
                            Builder(
                              builder: (BuildContext drawerContext) {
                                return IconButton(
                                  icon: const Icon(
                                    Icons.menu_rounded,
                                    color: AppColors.primaryWhite,
                                    size: 24,
                                  ),
                                  onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            // Person icon container
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primaryWhite,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGold.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.primaryDarkBlue,
                                size: 30,
                              ),
                            ),
                            AppSpacing.horizontalMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hi! $_studentName',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primaryWhite,
                                      fontSize: 24,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  AppSpacing.verticalXs,
                                  if (_studentClass.isNotEmpty)
                                    Text(
                                      _studentClass,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.primaryWhite.withValues(alpha: 0.8),
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (_studentAuid.isNotEmpty)
                                    Text(
                                      _studentAuid,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: isDarkMode ? AppColors.textMutedDark : AppColors.primaryWhite.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          );
                          _refreshUnreadCount();
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryWhite.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primaryWhite,
                                size: 22,
                              ),
                            ),
                            if (_unreadCount > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _unreadCount > 9 ? '9+' : '$_unreadCount',
                                    style: const TextStyle(
                                      color: AppColors.primaryWhite,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, bool isDarkMode) {
    final columns = ResponsiveLayout.gridColumns(context);
    final spacing = ResponsiveLayout.spacing(context);
    final padding = ResponsiveLayout.padding(context);

    return ListenableBuilder(
      listenable: _gridController,
      builder: (context, child) {
        return Padding(
          padding: padding.copyWith(top: 20),
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.95,
            ),
            itemCount: _features.length,
            itemBuilder: (context, index) {
              // Staggered animation for each tile
              final startInterval = (index * 0.08).clamp(0.0, 0.5);
              final endInterval = (startInterval + 0.4).clamp(0.0, 1.0);

              final itemAnimation = CurvedAnimation(
                parent: _gridController,
                curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
              );

              return FadeTransition(
                opacity: itemAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(itemAnimation),
                  child: FeatureTile(
                    title: _features[index].title,
                    subtitle: _features[index].subtitle,
                    icon: _features[index].icon,
                    color: _features[index].color,
                    index: index,
                    onTap: () {
                      AppRoutes.navigateTo(context, _features[index].route);
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}