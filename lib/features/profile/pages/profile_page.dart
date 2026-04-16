import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

import '../../../core/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_spacing.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _fullName = '';
  String _auid = '';
  String _department = '';
  String _email = '';
  String _joinedDate = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(AppConstants.userNameKey) ?? 'N/A';
      final auid = prefs.getString(AppConstants.auidKey) ?? 'N/A';
      final dept = prefs.getString(AppConstants.userDepartmentKey) ?? 'N/A';
      final email = prefs.getString(AppConstants.userEmailKey) ?? '';
      
      final rawJoined = prefs.getString(AppConstants.userJoinedKey) ?? '';
      String formattedJoined = 'N/A';
      if (rawJoined.isNotEmpty) {
        try {
          final dt = DateTime.parse(rawJoined);
          formattedJoined = DateFormat('MMMM d, yyyy').format(dt);
        } catch (e) {
          formattedJoined = rawJoined; // Fallback
        }
      }

      if (!mounted) return;
      setState(() {
        _fullName = name;
        _auid = auid;
        _department = dept;
        _email = email;
        _joinedDate = formattedJoined;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      developer.log('Error loading profile data: $e', name: 'ProfilePage');
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                padding: AppSpacing.paddingLg,
                child: Column(
                  children: [
                    _buildAvatar(isDarkMode),
                    AppSpacing.verticalLg,
                    _buildProfileCard(isDarkMode),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatar(bool isDarkMode) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.primaryWhite,
        shape: BoxShape.circle,
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: AppColors.primaryDarkBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Center(
        child: Text(
          _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: AppColors.primaryBlack.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Full Name', _fullName, Icons.person_outline, isDarkMode),
          const Divider(),
          _buildInfoRow('AUID', _auid, Icons.badge_outlined, isDarkMode),
          const Divider(),
          _buildInfoRow('Department', _department, Icons.account_balance_outlined, isDarkMode),
          if (_email.isNotEmpty) ...[
            const Divider(),
            _buildInfoRow('Email', _email, Icons.email_outlined, isDarkMode),
          ],
          const Divider(),
          _buildInfoRow('Joined Date', _joinedDate, Icons.calendar_today_outlined, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
