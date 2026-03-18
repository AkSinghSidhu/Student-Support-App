import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';

import '../../core/services/cache_service.dart';
import '../../core/services/background_service.dart';

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
  Future<void> _handleLogout(BuildContext dialogContext) async {
    // 1. Navigator.pop(dialogContext) — close the dialog
    Navigator.pop(dialogContext);
    
    // 2. NotificationService().stopAttendanceListener()
    // Not applicable since NotificationService doesn't have stopAttendanceListener
    
    // 3. try/catch: await CacheService.clearAllUserCache()
    try {
      await CacheService.clearAllUserCache();
    } catch (e) {
      // ignore
    }
    
    // 4. cancelAttendanceCheck()
    cancelAttendanceCheck();
    
    // 5. try/catch: final prefs = await SharedPreferences.getInstance()
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_in_auid');
      await prefs.remove('remember_me');
      await prefs.remove('theme_mode');
    } catch (e) {
      // ignore
    }
    
    // 6. if (mounted): AppRoutes.navigateClearStack(context, AppRoutes.login)
    if (mounted) {
      AppRoutes.navigateClearStack(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        children: [
          // SECTION 1 — HEADER
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
          
          // SECTIONS 2 & 3 — Wrapped in Expanded + scroll
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 2 — APPEARANCE
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'APPEARANCE',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
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
                      ],
                    ),
                  ),
                  
                  // SECTION 3 — MENU ITEMS
                  Divider(
                    color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.2),
                    height: 32,
                  ),
                  
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: Text(
                      'View your details',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile page coming soon')),
                      );
                    },
                  ),
                  
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: Text(
                      'Terms and conditions',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // SECTION 4 — LOGOUT
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
          
          // SECTION 5 — VERSION
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Center(
              child: Text(
                'Version 1.0.0',
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
