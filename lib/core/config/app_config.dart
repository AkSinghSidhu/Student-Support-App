import 'package:flutter/foundation.dart';

enum AppEnvironment { development, production }

class AppConfig {
  final String appName;
  final String firebaseDbUrl;
  final bool isDebug;
  final AppEnvironment environment;

  const AppConfig._({
    required this.appName,
    required this.firebaseDbUrl,
    required this.isDebug,
    required this.environment,
  });

  static const AppConfig dev = AppConfig._(
    appName: 'UniSupport (Dev)',
    firebaseDbUrl:
        'https://studentsupporttest-default-rtdb.asia-southeast1.firebasedatabase.app',
    isDebug: true,
    environment: AppEnvironment.development,
  );

  static const AppConfig prod = AppConfig._(
    appName: 'UniSupport',
    firebaseDbUrl:
        'https://studentsupporttest-default-rtdb.asia-southeast1.firebasedatabase.app',
    isDebug: false,
    environment: AppEnvironment.production,
  );

  static AppConfig get current => kDebugMode ? dev : prod;

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;
}
