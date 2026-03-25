import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme_provider.dart';
import 'dart:developer' as developer;
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/background_service.dart';
import '../../core/services/notice_service.dart';

class AppDrawer extends StatefulWidget {
  final String studentName;
  final String studentAuid;
  final String studentDepartment;

  const AppDrawer({
    super.key,
    required this.studentName,
    required this.studentAuid,
    required this.studentDepartment,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = info.version);
      }
    } catch (e) {
      developer.log(
        'Failed to load app version: $e',
        name: 'AppDrawer',
      );
      if (mounted) {
        setState(() => _appVersion = '0.1.0');
      }
    }
  }


  Future<void> _handleLogout(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);

    NoticeService().stopListening();
    cancelAttendanceCheck();

    try {
      await CacheService.clearAllUserCache();
    } catch (e) {
      developer.log('Logout cleanup error: $e', name: 'AppDrawer');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.auidKey);
      await prefs.remove(AppConstants.rememberMeKey);
      await prefs.remove(AppConstants.themeModeKey);
    } catch (e) {
      developer.log('Logout cleanup error: $e', name: 'AppDrawer');
    }

    if (mounted) {
      AppRoutes.navigateClearStack(context, AppRoutes.login);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSectionLabel(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.2),
      height: 8,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        children: [
          // ─── HEADER ───
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardBackgroundDark : null,
              gradient: isDarkMode ? null : AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryWhite,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.primaryDarkBlue,
                        size: 26,
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGold,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDarkBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Hi, ${widget.studentName}',
                  style: const TextStyle(
                    color: AppColors.primaryWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.studentAuid} • ${widget.studentDepartment}',
                  style: TextStyle(
                    color: AppColors.primaryWhite.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ─── SCROLLABLE BODY ───
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── ACCOUNT ───
                  _buildSectionLabel('ACCOUNT', isDarkMode),
                  _buildTile(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Profile',
                    subtitle: 'View your details',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile page coming soon')),
                      );
                    },
                  ),
                  _buildTile(
                    icon: Icons.history,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'My History',
                    subtitle: 'Complaints & feedback',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.history);
                    },
                  ),
                  _buildTile(
                    icon: Icons.lock_outline,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Change Password',
                    subtitle: 'Coming soon',
                    isDarkMode: isDarkMode,
                    opacity: 0.4,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Available after account upgrade')),
                      );
                    },
                  ),

                  _buildDivider(isDarkMode),

                  // ─── DISPLAY ───
                  _buildSectionLabel('DISPLAY', isDarkMode),

                  // Theme toggle — kept exactly as original
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
                        border: Border.all(
                          color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return Row(
                            children: [
                              _buildThemeButton(
                                themeProvider: themeProvider,
                                mode: ThemeMode.light,
                                label: '☀️  Light',
                                isDarkMode: isDarkMode,
                              ),
                              _buildThemeButton(
                                themeProvider: themeProvider,
                                mode: ThemeMode.dark,
                                label: '🌙  Dark',
                                isDarkMode: isDarkMode,
                              ),
                              _buildThemeButton(
                                themeProvider: themeProvider,
                                mode: ThemeMode.system,
                                label: '📱  System',
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),


                  _buildDivider(isDarkMode),

                  // ─── GENERAL ───
                  _buildSectionLabel('GENERAL', isDarkMode),

                  // About
                  _buildTile(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF6B7280),
                    title: 'About',
                    subtitle: 'Version $_appVersion',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
                            contentPadding: const EdgeInsets.all(24),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryDarkBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.school_rounded, color: AppColors.primaryWhite, size: 36),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Student Support App',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Version $_appVersion',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'Built for university students to track attendance, notices, syllabus and more.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Developed by Supan & AkSinghSidhu',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  // Privacy Policy
                  _buildTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Privacy Policy',
                    subtitle: 'Terms and conditions',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ─── LOGOUT ───
          Divider(
            color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.2),
            height: 1,
            thickness: 1,
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Log Out?'),
                    content: const Text('Are you sure you want to log out?'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _handleLogout(dialogContext),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // ─── VERSION ───
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Center(
              child: Text(
                'Version $_appVersion',
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required ThemeProvider themeProvider,
    required ThemeMode mode,
    required String label,
    required bool isDarkMode,
  }) {
    final isSelected = themeProvider.themeMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => themeProvider.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGold : Colors.transparent,
            borderRadius: isSelected ? BorderRadius.circular(8) : BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? AppColors.primaryDarkBlue
                  : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }
}
