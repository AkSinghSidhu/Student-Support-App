import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/app_constants.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../core/repositories/attendance_repository.dart';
import '../../../models/models.dart';

/// Attendance page with summary and push notification alerts.
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Hard-coded 75% threshold for alerts
  static const double alertThreshold = AppConstants.attendanceThreshold;
  bool _isLoading = true;
  String? _errorMessage;

  List<SubjectModel> _subjects = [];
  final _repo = AttendanceRepository();

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _subjects = [];
    });
    await _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auid = prefs.getString(AppConstants.auidKey);

      if (auid == null || auid.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final subjects = await _repo.getSubjects(auid);
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
          if (_subjects.isEmpty) {
            _errorMessage = 'No attendance data found';
          }
        });
      }
    } catch (e) {
      if (mounted && _subjects.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load attendance data';
        });
      }
    }
  }

  Color _getColor(double percent) {
    if (percent >= 75) return AppColors.success;
    if (percent >= 65) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        appBar: const CustomAppBar(title: 'Attendance'),
        body: AttendanceShimmer(isDarkMode: isDarkMode),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        appBar: const CustomAppBar(title: 'Attendance'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              AppSpacing.verticalMd,
              Text(_errorMessage!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              AppSpacing.verticalMd,
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadAttendanceData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final totalAttended = _subjects.fold<int>(0, (s, e) => s + e.attended);
    final totalClasses = _subjects.fold<int>(0, (s, e) => s + e.total);
    final overall = totalClasses > 0 ? totalAttended / totalClasses * 100 : 0.0;

    // Count low attendance subjects
    final lowSubjects = _subjects.where((s) => s.isLow).toList();

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: const CustomAppBar(title: 'Attendance'),
      body: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.attendanceColor,
              child: ListView(
                padding: const EdgeInsets.all(20),
        children: [
          // Overall card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                overall < alertThreshold
                    ? AppColors.error.withValues(alpha: 0.9)
                    : AppColors.attendanceColor.withValues(alpha: 0.9),
                overall < alertThreshold
                    ? AppColors.error
                    : AppColors.attendanceColor,
              ]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('Overall: ${overall.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryWhite)),
                AppSpacing.verticalSm,
                Text('$totalAttended / $totalClasses classes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryWhite.withValues(alpha: 0.8))),
                if (overall < alertThreshold) ...[
                  AppSpacing.verticalSm,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryWhite.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.primaryWhite, size: 16),
                        AppSpacing.horizontalSm,
                        Text('Below 75% threshold', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryWhite)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Alerts info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lowSubjects.isNotEmpty
                  ? AppColors.error.withValues(alpha: 0.1)
                  : (isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight),
              borderRadius: BorderRadius.circular(14),
              border: lowSubjects.isNotEmpty
                  ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: lowSubjects.isNotEmpty
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.attendanceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    lowSubjects.isNotEmpty ? Icons.notification_important : Icons.notifications_active,
                    color: lowSubjects.isNotEmpty ? AppColors.error : AppColors.attendanceColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lowSubjects.isNotEmpty ? 'Low Attendance Alert' : 'All Good!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: lowSubjects.isNotEmpty ? AppColors.error : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        lowSubjects.isNotEmpty
                            ? '${lowSubjects.length} subject${lowSubjects.length > 1 ? "s" : ""} below 75%: ${lowSubjects.map((s) => s.name).join(", ")}'
                            : 'All subjects are above 75% threshold',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalLg,
          Text('Subject-wise', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          AppSpacing.verticalSm,
          ..._subjects.map((s) {
            final p = s.percent;
            final isLow = s.isLow;
              return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: isLow ? Border.all(color: AppColors.error.withValues(alpha: 0.3)) : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Row(children: [
                      Flexible(
                        child: Text(s.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight), overflow: TextOverflow.ellipsis),
                      ),
                      if (isLow) ...[
                        AppSpacing.horizontalSm,
                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                      ],
                    ]),
                  ),
                  AppSpacing.horizontalSm,
                  Text(s.percentFormatted, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _getColor(p), fontWeight: FontWeight.w600)),
                ]),
                AppSpacing.verticalXs,
                Text('${s.attended} / ${s.total} classes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                AppSpacing.verticalSm,
                LinearProgressIndicator(value: p / 100, backgroundColor: _getColor(p).withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation(_getColor(p))),
              ]),
            );
          }),
        ],
      ),
      ),
    );
  }
}