import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

import 'core/routes/app_routes.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart'; // Import background service
import 'core/services/notice_service.dart';
import 'core/services/cache_service.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/queue_service.dart';
import 'core/services/notification_store.dart';
import 'package:hive_flutter/hive_flutter.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize offline cache
  await CacheService.initialize();

  // Open notifications Hive box
  await Hive.openBox('notifications');
  
  // Initialize notification service (channels, permissions)
  await NotificationService().initialize();
  
  // Initialize and start the background service for attendance monitoring
  initializeBackgroundService();
  
  // Start listening for new notices and send notifications
  await NoticeService().startListening();
  
  // Check if user is already logged in
  final prefs = await SharedPreferences.getInstance();
  final loggedInAuid = prefs.getString('logged_in_auid');
  final isLoggedIn = loggedInAuid != null && loggedInAuid.isNotEmpty;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: StudentSupportApp(isLoggedIn: isLoggedIn),
    ),
  );
}


class StudentSupportApp extends StatefulWidget {
  final bool isLoggedIn;
  
  const StudentSupportApp({super.key, required this.isLoggedIn});

  @override
  State<StudentSupportApp> createState() => _StudentSupportAppState();
}

class _StudentSupportAppState extends State<StudentSupportApp> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isSyncing = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      // If connected to mobile or wifi
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        final pendingItems = await QueueService.getPendingItems();
        
        if (pendingItems.isNotEmpty && !_isSyncing) {
          _isSyncing = true;
          
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Sending your saved drafts...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
          
          await QueueService.retryAll();

          // Store in-app notification for draft sync
          await NotificationStore.addNotification(
            title: 'Drafts Sent',
            body: 'Your saved drafts were submitted successfully',
            type: 'draft',
          );
          
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('All drafts sent successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          _isSyncing = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          scaffoldMessengerKey: _scaffoldMessengerKey,
          title: 'Student Support',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: widget.isLoggedIn ? AppRoutes.home : AppRoutes.login,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
