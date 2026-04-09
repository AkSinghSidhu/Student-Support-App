import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // In Flutter, widget-level error boundaries are typically handled via ErrorWidget.builder 
    // or by overriding specific builds. However, we can use a custom error builder for descendants.
  }

  void _resetError() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // By wrapping in a builder that uses the custom error widget if a build error occurs
    // we can catch some Widget-level exceptions if we manually wrap tree parts.
    // Realistically, Flutter catches build errors and uses ErrorWidget.builder.
    // If we want a true boundary, we just let ErrorWidget.builder handle it, 
    // or we catch async errors.
    
    // Using a normal builder as a placeholder for the error state if we caught any locally.
    if (_error != null) {
      final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
      
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'An unexpected error occurred. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _resetError,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkBlue,
                    foregroundColor: AppColors.textPrimaryDark, // white text
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Helper function to configure the global ErrorWidget.builder
/// so it uses the ErrorBoundary UI seamlessly.
void setupErrorBoundary() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    developer.log(
      'UI Rendering Error: ${details.exception}',
      name: 'ErrorBoundary',
      error: details.exception,
      stackTrace: details.stack,
    );

    return Builder(
      builder: (context) {
        // Fallback safely if provider is not available this deep
        bool isDarkMode = true;
        try {
          isDarkMode = context.watch<ThemeProvider>().isDarkMode;
        } catch (_) {
          // Ignore
        }
        
        return Material(
          color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Component Error',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This part of the app encountered an error.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  };
}
