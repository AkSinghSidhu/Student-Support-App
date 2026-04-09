import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/notification_store.dart';
import '../../core/di/service_locator.dart';
import '../../shared/widgets/custom_app_bar.dart';

/// Full-page notification center showing attendance alerts, draft syncs, etc.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = sl<NotificationStore>().getAll();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _notificationsFuture = sl<NotificationStore>().getAll();
      });
    }
  }

  Future<void> _markAllRead() async {
    await sl<NotificationStore>().markAllAsRead();
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  Future<void> _clearAll() async {
    await sl<NotificationStore>().clearAll();
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications cleared')),
      );
    }
  }

  String _timeAgo(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'attendance':
        return Icons.school_outlined;
      case 'notice':
        return Icons.campaign_outlined;
      case 'complaint':
        return Icons.report_outlined;
      case 'feedback':
        return Icons.chat_bubble_outline;
      case 'draft':
        return Icons.cloud_upload_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'attendance':
        return AppColors.error;
      case 'notice':
        return AppColors.info;
      case 'complaint':
        return AppColors.warning;
      case 'feedback':
        return AppColors.success;
      case 'draft':
        return AppColors.feedbackColor;
      default:
        return AppColors.textMutedLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          IconButton(
            icon: Icon(
              Icons.done_all,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primaryWhite,
              size: 22,
            ),
            tooltip: 'Mark all read',
            onPressed: _markAllRead,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primaryWhite,
              size: 22,
            ),
            tooltip: 'Clear all',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading(isDarkMode);
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState(isDarkMode);
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildNotificationItem(item, isDarkMode);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item, bool isDarkMode) {
    final isRead = item['isRead'] == true;
    final type = item['type'] as String? ?? 'notice';
    final iconColor = _colorForType(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isRead
            ? (isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight)
            : (isDarkMode
                ? AppColors.cardBackgroundDark.withValues(alpha: 0.5)
                : const Color(0xFFF8F9FF)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead
              ? AppColors.transparent
              : iconColor.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () async {
            final id = item['id'] as String? ?? '';
            if (id.isNotEmpty) {
              await sl<NotificationStore>().markAsRead(id);
              _refresh();
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconForType(type),
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['body'] as String? ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeAgo(item['timestamp'] as String? ?? ''),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Unread dot / arrow
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: isRead
                      ? Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: isDarkMode
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        )
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attendance alerts and app updates\nwill appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Circle shimmer
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title shimmer
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Body shimmer
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Timestamp shimmer
                    Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
