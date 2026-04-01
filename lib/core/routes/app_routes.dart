import 'package:flutter/material.dart';
import '../../pages/login_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/feedback/pages/feedback_page.dart';
import '../../features/complaint/pages/complaint_page.dart';
import '../../features/syllabus/pages/syllabus_page.dart';
import '../../features/resources/pages/resources_page.dart';
import '../../features/attendance/pages/attendance_page.dart';
import '../../features/notices/pages/notices_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/history/history_page.dart';

/// Named route definitions and route generator for clean navigation.
class AppRoutes {
  AppRoutes._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Route names
  static const String login = '/login';
  static const String home = '/home';
  static const String feedback = '/feedback';
  static const String complaint = '/complaint';
  static const String syllabus = '/syllabus';
  static const String resources = '/resources';
  static const String attendance = '/attendance';
  static const String notices = '/notices';
  static const String onboarding = '/onboarding';
  static const String history = '/history';

  /// Route generator for MaterialApp
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildPageRoute(const LoginPage(), settings);
      case home:
        return _buildPageRoute(const HomePage(), settings);
      case feedback:
        return _buildPageRoute(const FeedbackPage(), settings);
      case complaint:
        return _buildPageRoute(const ComplaintPage(), settings);
      case syllabus:
        return _buildPageRoute(const SyllabusPage(), settings);
      case resources:
        return _buildPageRoute(const ResourcesPage(), settings);
      case attendance:
        return _buildPageRoute(const AttendancePage(), settings);
      case notices:
        return _buildPageRoute(const NoticesPage(), settings);
      case onboarding:
        return _buildPageRoute(const OnboardingPage(), settings);
      case history:
        return _buildPageRoute(const HistoryPage(), settings);
      default:
        return _buildPageRoute(const LoginPage(), settings);
    }
  }

  /// Custom page route with smooth slide transition
  static PageRouteBuilder<dynamic> _buildPageRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Navigate with custom animation
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// Navigate and replace current route
  static void navigateReplace(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  /// Navigate and clear all previous routes
  static void navigateClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}
