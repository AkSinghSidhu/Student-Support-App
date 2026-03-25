import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/services/notice_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/shimmer_loader.dart';

/// Notices page with announcements list and filters.
class NoticesPage extends StatefulWidget {
  const NoticesPage({super.key});

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Academic', 'Events', 'Exam', 'General'];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final Stream<List<Map<String, dynamic>>> _noticesStream;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _noticesStream = NoticeService().noticesStream();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _listController.forward();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _refresh() async {
    _listController.reset();
    _listController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredNotices(List<Map<String, dynamic>> notices) {
    return notices.where((n) {
      final matchesFilter = _selectedFilter == 'All' || n['category'] == _selectedFilter;
      if (!matchesFilter) return false;
      
      if (_searchQuery.isEmpty) return true;
      
      final title = (n['title'] as String).toLowerCase();
      final category = (n['category'] as String? ?? '').toLowerCase();
      return title.contains(_searchQuery) || category.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: const CustomAppBar(title: 'Notices'),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            hint: 'Search notices...',
            isDarkMode: isDarkMode,
          ),
          // Filter chips
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (c, i) {
                final isActive = _selectedFilter == _filters[i];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFilter = _filters[i]);
                    _listController.reset();
                    _listController.forward();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.noticesColor : (isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? AppColors.noticesColor : (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(_filters[i], style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    )),
                  ),
                );
              },
            ),
          ),
          // Notices list from Firebase
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.noticesColor,
              child: StreamBuilder<List<Map<String, dynamic>>>(
              initialData: CacheService.getNotices(),
              stream: _noticesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return NoticesShimmer(isDarkMode: isDarkMode);
                }

                if (snapshot.hasError && !snapshot.hasData) {
                  return Center(child: Text('Error loading notices: ${snapshot.error}'));
                }

                final notices = snapshot.data ?? [];
                final filtered = _filteredNotices(notices);

                if (filtered.isEmpty) {
                  return const Center(child: Text('No notices found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (c, i) {
                    final startInterval = (i * 0.1).clamp(0.0, 0.6);
                    final endInterval = (startInterval + 0.4).clamp(0.0, 1.0);
                    final itemAnim = CurvedAnimation(
                      parent: _listController,
                      curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
                    );
                    return FadeTransition(
                      opacity: itemAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(itemAnim),
                        child: _buildNoticeCard(filtered[i], isDarkMode),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildNoticeCard(Map<String, dynamic> notice, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: notice['important'] ? Border.all(color: AppColors.error.withValues(alpha: 0.5)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.noticesColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(notice['category'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.noticesColor)),
          ),
          if (notice['important']) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
              child: const Text('Important', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error)),
            ),
          ],
          const Spacer(),
          Text(_formatDate(notice['date']), style: TextStyle(fontSize: 11, color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ]),
        const SizedBox(height: 10),
        Text(notice['title'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
      ]),
    );
  }
}
