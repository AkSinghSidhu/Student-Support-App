import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'core/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_provider.dart';

import 'core/routes/app_routes.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart'; // Import background service
import 'core/services/notice_service.dart';
import 'core/services/cache_service.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' show PlatformDispatcher;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/queue_service.dart';
import 'core/services/notification_store.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'shared/widgets/offline_banner.dart';
import 'core/di/service_locator.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log(
        'Flutter error: ${details.exception}',
        name: 'GlobalErrorHandler',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      developer.log(
        'Platform error: $error',
        name: 'GlobalErrorHandler',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    await Firebase.initializeApp();
    
    // Initialize offline cache
    await CacheService.initialize();

    // Open notifications Hive box
    await Hive.openBox(AppConstants.notificationsBoxKey);
    
    // Dependency Injection Setup
    await setupServiceLocator();
    
    // Initialize notification service (channels, permissions)
    await sl<NotificationService>().initialize();
    
    // Initialize and start the background service for attendance monitoring
    initializeBackgroundService();
    
    // Start listening for new notices and send notifications
    await sl<NoticeService>().startListening();
    
    // Check if user is already logged in
    final prefs = await SharedPreferences.getInstance();
    final loggedInAuid = prefs.getString(AppConstants.auidKey);
    final isLoggedIn = loggedInAuid != null && loggedInAuid.isNotEmpty;
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: StudentSupportApp(isLoggedIn: isLoggedIn, onboardingDone: onboardingDone),
      ),
    );
  } catch (e, stack) {
    developer.log(
      'FATAL startup error: $e',
      name: 'main',
      error: e,
      stackTrace: stack,
    );
    // Still run the app even if init fails
    // so user sees something instead of blank screen
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Startup error — please reinstall'),
            ),
          ),
        ),
      ),
    );
  }
}


class StudentSupportApp extends StatefulWidget {
  final bool isLoggedIn;
  final bool onboardingDone;
  
  const StudentSupportApp({
    super.key, 
    required this.isLoggedIn,
    required this.onboardingDone,
  });

  @override
  State<StudentSupportApp> createState() => _StudentSupportAppState();
}

class _StudentSupportAppState extends State<StudentSupportApp> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isSyncing = false;
  bool _isOffline = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      // Update offline state
      if (mounted) {
        setState(() {
          _isOffline = results.every((r) => r == ConnectivityResult.none);
        });
      }

      // Guard 1: If offline, return silently
      final isOnline = results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi);
      if (!isOnline) return;

      // Guard 2: If already syncing, skip
      if (_isSyncing) return;

      // Guard 3: If queue is empty, return silently — no snackbar, no noise
      final pendingItems = await QueueService.getPendingItems();
      if (pendingItems.isEmpty) return;

      _isSyncing = true;

      try {
        final result = await QueueService.retryAll();

        // Only show messages if something actually happened
        if (result.sentCount > 0) {
          await NotificationStore.addNotification(
            title: 'Drafts Sent',
            body: '${result.sentCount} draft${result.sentCount == 1 ? '' : 's'} submitted successfully',
            type: 'draft',
          );

          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('${result.sentCount} draft${result.sentCount == 1 ? '' : 's'} sent successfully!'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        if (result.expiredCount > 0) {
          // Small delay so both snackbars show sequentially
          if (result.sentCount > 0) {
            await Future.delayed(const Duration(seconds: 2));
          }

          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('${result.expiredCount} expired draft${result.expiredCount == 1 ? ' was' : 's were'} removed'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        developer.log('Draft sync error: $e', name: 'main');
      } finally {
        _isSyncing = false;
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
          navigatorKey: AppRoutes.navigatorKey,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          title: 'Student Support',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: widget.isLoggedIn 
              ? AppRoutes.home 
              : (widget.onboardingDone ? AppRoutes.login : AppRoutes.onboarding),
          onGenerateRoute: AppRoutes.generateRoute,
          builder: (context, child) => OfflineBanner(
            isOffline: _isOffline,
            child: child!,
          ),
        );
      },
    );
  }
}
