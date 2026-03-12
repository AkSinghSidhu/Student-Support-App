import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart'; // Import background service
import 'core/services/notice_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notification service (channels, permissions)
  await NotificationService().initialize();
  
  // Initialize and start the background service for attendance monitoring
  await initializeBackgroundService();
  
  // Start listening for new notices and send notifications
  await NoticeService().startListening();
  
  // Check if user is already logged in
  final prefs = await SharedPreferences.getInstance();
  final loggedInAuid = prefs.getString('logged_in_auid');
  final isLoggedIn = loggedInAuid != null && loggedInAuid.isNotEmpty;
  
  runApp(StudentSupportApp(isLoggedIn: isLoggedIn));
}


class StudentSupportApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const StudentSupportApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Support',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: isLoggedIn ? AppRoutes.home : AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

