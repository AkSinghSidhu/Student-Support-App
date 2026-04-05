import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/database_service.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/shimmer_loader.dart';
import '../../shared/widgets/loading_overlay.dart';
import 'dart:developer' as developer;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _auid;
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _feedback = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _auid = prefs.getString(AppConstants.auidKey);

      if (_auid == null || _auid!.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final complaintsSnapshot = await DatabaseService.db.child('complaints').child(_auid!).once();
      final feedbackSnapshot = await DatabaseService.db.child('feedback').child(_auid!).once();

      final List<Map<String, dynamic>> loadedComplaints = [];
      if (complaintsSnapshot.snapshot.value != null) {
        final complaintsRaw = complaintsSnapshot.snapshot.value;
        if (complaintsRaw is! Map) {
          developer.log('Invalid complaints data format', name: 'HistoryPage');
          if (mounted) setState(() { _isLoading = false; });
          return;
        }
        final complaintsData = Map<String, dynamic>.from(complaintsRaw);
        
        complaintsData.forEach((key, value) {
          if (value is! Map) return;
          final item = Map<String, dynamic>.from(value);
          item['id'] = key;
          loadedComplaints.add(item);
        });
      }

      final List<Map<String, dynamic>> loadedFeedback = [];
      if (feedbackSnapshot.snapshot.value != null) {
        final feedbackRaw = feedbackSnapshot.snapshot.value;
        if (feedbackRaw is! Map) {
          developer.log('Invalid feedback data format', name: 'HistoryPage');
          if (mounted) setState(() { _isLoading = false; });
          return;
        }
        final feedbackData = Map<String, dynamic>.from(feedbackRaw);
        
        feedbackData.forEach((key, value) {
          if (value is! Map) return;
          final item = Map<String, dynamic>.from(value);
          item['id'] = key;
          loadedFeedback.add(item);
        });
      }

      // Sort by descending date
      loadedComplaints.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
      loadedFeedback.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));

      if (mounted) {
        setState(() {
          _complaints = loadedComplaints;
          _feedback = loadedFeedback;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown Date';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM d, y, h:mm a').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case AppConstants.statusResolved:
        return AppColors.success;
      case AppConstants.statusRejected:
        return AppColors.error;
      case AppConstants.statusPending:
      default:
        return AppColors.warning;
    }
  }

  Widget _buildTabBar(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue,
          borderRadius: BorderRadius.circular(50),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelPadding: EdgeInsets.zero,
        labelColor: isDarkMode ? AppColors.primaryBlack : AppColors.primaryWhite,
        unselectedLabelColor: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        dividerColor: AppColors.transparent,
        tabs: const [
          Tab(text: AppConstants.tabComplaints),
          Tab(text: AppConstants.tabFeedback),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> item, bool isComplaint, bool isDarkMode) {
    final status = item['status'] ?? AppConstants.statusPending;
    final statusColor = _getStatusColor(status);
    final title = isComplaint ? (item['subject'] ?? 'No Subject') : (item['category'] ?? 'General Feedback');
    final description = item['message'] ?? item['description'] ?? 'No Description provided.';
    final date = _formatDate(item['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      date,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.horizontalSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16),
                  AppSpacing.verticalSm,
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  AppSpacing.verticalXs,
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (!isComplaint && item['rating'] != null) ...[
                    AppSpacing.verticalSm,
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.warning, size: 16),
                        AppSpacing.horizontalXs,
                        Text(
                          '${item['rating']} / 5',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool isComplaint, bool isDarkMode) {
    if (items.isEmpty) {
      return EmptyState(
        icon: isComplaint ? Icons.report_problem_outlined : Icons.feedback_outlined,
        title: isComplaint ? 'No complaints found' : 'No feedback found',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(context, items[index], isComplaint, isDarkMode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: const CustomAppBar(title: 'History'),
      body: Column(
        children: [
          _buildTabBar(context, isDarkMode),
          Expanded(
            child: _isLoading
                ? ShimmerLoader(
                    isDarkMode: isDarkMode,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 4,
                      itemBuilder: (_, __) => ShimmerCard(height: 80, isDarkMode: isDarkMode),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildList(_complaints, true, isDarkMode),
                      _buildList(_feedback, false, isDarkMode),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
