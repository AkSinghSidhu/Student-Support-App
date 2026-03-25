import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;

  const ShimmerLoader({
    super.key,
    required this.isDarkMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDarkMode
          ? AppColors.cardBackgroundDark
          : const Color(0xFFE0E0E0),
      highlightColor: isDarkMode
          ? AppColors.surfaceDark
          : const Color(0xFFF5F5F5),
      child: child,
    );
  }
}

// Reusable shimmer card skeleton
class ShimmerCard extends StatelessWidget {
  final double height;
  final bool isDarkMode;

  const ShimmerCard({
    super.key,
    this.height = 80,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      isDarkMode: isDarkMode,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppColors.cardBackgroundDark
              : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// Attendance shimmer — card with progress bar
class AttendanceShimmer extends StatelessWidget {
  final bool isDarkMode;
  const AttendanceShimmer({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      isDarkMode: isDarkMode,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 90,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.cardBackgroundDark
                : AppColors.cardBackgroundLight,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// Notices shimmer
class NoticesShimmer extends StatelessWidget {
  final bool isDarkMode;
  const NoticesShimmer({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      isDarkMode: isDarkMode,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 6,
        itemBuilder: (_, __) => ShimmerCard(
          height: 80,
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }
}
