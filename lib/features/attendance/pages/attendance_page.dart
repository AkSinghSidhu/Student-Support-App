import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';

/// Attendance page with summary and push notification alerts.
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Hard-coded 75% threshold for alerts
  static const double alertThreshold = 75.0;
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auid = prefs.getString('logged_in_auid');

      if (auid == null || auid.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://studentsupporttest-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref();

      final snapshot = await database.child('attendance').child(auid).child('subjects').get();

      if (snapshot.exists && mounted) {
        final subjectsData = Map<String, dynamic>.from(snapshot.value as Map);
        final List<Map<String, dynamic>> loadedSubjects = [];

        subjectsData.forEach((key, value) {
          final subject = Map<String, dynamic>.from(value as Map);
          final attended = (subject['attended'] as num).toInt();
          final total = (subject['total'] as num).toInt();
          final percent = total > 0 ? (attended / total * 100) : 0.0;

          loadedSubjects.add({
            'code': key,
            'name': subject['name'] ?? key,
            'attended': attended,
            'total': total,
            'percent': percent,
          });
        });

        setState(() {
          _subjects = loadedSubjects;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No attendance data found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load attendance data';
      });
    }
  }

  Color _getColor(double percent) {
    if (percent >= 75) return AppColors.success;
    if (percent >= 65) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surfaceLight,
        appBar: const CustomAppBar(title: 'Attendance'),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.attendanceColor),
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.surfaceLight,
        appBar: const CustomAppBar(title: 'Attendance'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
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

    final totalAttended = _subjects.fold<int>(0, (s, e) => s + (e['attended'] as int));
    final totalClasses = _subjects.fold<int>(0, (s, e) => s + (e['total'] as int));
    final overall = totalClasses > 0 ? totalAttended / totalClasses * 100 : 0.0;

    // Count low attendance subjects
    final lowSubjects = _subjects.where((s) => (s['percent'] as double) < alertThreshold).toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: const CustomAppBar(title: 'Attendance'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Overall card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                overall < alertThreshold 
                    ? AppColors.error.withOpacity(0.9)
                    : AppColors.attendanceColor.withOpacity(0.9),
                overall < alertThreshold 
                    ? AppColors.error 
                    : AppColors.attendanceColor,
              ]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('Overall: ${overall.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('$totalAttended / $totalClasses classes',
                    style: TextStyle(color: Colors.white.withOpacity(0.8))),
                if (overall < alertThreshold) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Below 75% threshold', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: lowSubjects.isNotEmpty 
                  ? Border.all(color: AppColors.error.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: lowSubjects.isNotEmpty 
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.attendanceColor.withOpacity(0.1),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600, 
                          fontSize: 14,
                          color: lowSubjects.isNotEmpty ? AppColors.error : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lowSubjects.isNotEmpty
                            ? '${lowSubjects.length} subject${lowSubjects.length > 1 ? "s" : ""} below 75%: ${lowSubjects.map((s) => s["name"]).join(", ")}'
                            : 'All subjects are above 75% threshold',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Subject-wise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._subjects.map((s) {
            final p = s['percent'] as double;
            final isLow = p < alertThreshold;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground, 
                borderRadius: BorderRadius.circular(12),
                border: isLow ? Border.all(color: AppColors.error.withOpacity(0.3)) : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Row(children: [
                      Flexible(
                        child: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      ),
                      if (isLow) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                      ],
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text('${p.toStringAsFixed(1)}%', style: TextStyle(color: _getColor(p), fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Text('${s['attended']} / ${s['total']} classes', 
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: p / 100, backgroundColor: _getColor(p).withOpacity(0.2), valueColor: AlwaysStoppedAnimation(_getColor(p))),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
