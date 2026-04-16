import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_spacing.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> with SingleTickerProviderStateMixin {
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

    _animationController.forward();
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
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListenableBuilder(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                isDarkMode: isDarkMode,
                icon: Icons.data_usage_outlined,
                title: 'What data we collect',
                content: 'We collect your AUID, name, department, complaints, and feedback.',
              ),
              AppSpacing.verticalLg,
              _buildSection(
                isDarkMode: isDarkMode,
                icon: Icons.psychology_outlined,
                title: 'How we use it',
                content: 'Your data is solely used to provide student support services within the university.',
              ),
              AppSpacing.verticalLg,
              _buildSection(
                isDarkMode: isDarkMode,
                icon: Icons.security_outlined,
                title: 'Data storage',
                content: 'Data is stored securely in Firebase with encryption to ensure maximum protection.',
              ),
              AppSpacing.verticalLg,
              _buildSection(
                isDarkMode: isDarkMode,
                icon: Icons.visibility_off_outlined,
                title: 'Data sharing',
                content: 'Your information is strictly confidential and is never shared with third parties.',
              ),
              AppSpacing.verticalLg,
              _buildSection(
                isDarkMode: isDarkMode,
                icon: Icons.contact_support_outlined,
                title: 'Contact',
                content: 'For any privacy-related concerns, reach out to us at: support@university.edu',
              ),
              AppSpacing.verticalXl,
              Center(
                child: Text(
                  'Last updated: April 2026',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ),
              AppSpacing.verticalXl,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String content,
  }) {
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
          Row(
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
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
