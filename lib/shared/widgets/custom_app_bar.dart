import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Custom app bar with gradient background and consistent styling.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool useGradient;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
    this.useGradient = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return Container(
      decoration: useGradient
          ? BoxDecoration(
              color: isDarkMode ? AppColors.surfaceDark : null,
              gradient: isDarkMode ? null : AppColors.primaryGradient,
            )
          : BoxDecoration(
              color: isDarkMode ? AppColors.surfaceDark : AppColors.primaryDarkBlue,
            ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: AppColors.primaryWhite,
                    size: 20,
                  ),
                  splashRadius: 24,
                )
              else
                const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryWhite,
                    letterSpacing: 0.3,
                  ),
                  textAlign: showBackButton ? TextAlign.left : TextAlign.center,
                ),
              ),
              if (actions != null) ...actions! else const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient header section for feature pages
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final double height;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : null,
        gradient: isDarkMode ? null : AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppColors.primaryGold,
                ),
              ),
              AppSpacing.verticalSm,
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryWhite,
              ),
            ),
            if (subtitle != null) ...[
              AppSpacing.verticalXs,
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryWhite.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
