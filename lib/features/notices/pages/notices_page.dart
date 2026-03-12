import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/services/notice_service.dart';

/// Notices page with announcements list and filters.
class NoticesPage extends StatefulWidget {
  const NoticesPage({super.key});

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Academic', 'Events', 'Exam', 'General'];

  List<Map<String, dynamic>> _filteredNotices(List<Map<String, dynamic>> notices) =>
      _selectedFilter == 'All'
          ? notices
          : notices.where((n) => n['category'] == _selectedFilter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: const CustomAppBar(title: 'Notices'),
      body: Column(
        children: [
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
                  onTap: () => setState(() => _selectedFilter = _filters[i]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.noticesColor : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? AppColors.noticesColor : AppColors.textMuted.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(_filters[i], style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    )),
                  ),
                );
              },
            ),
          ),
          // Notices list from Firebase
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: NoticeService().noticesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
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
                  itemBuilder: (c, i) => _buildNoticeCard(filtered[i]),
                );
              },
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

  Widget _buildNoticeCard(Map<String, dynamic> notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: notice['important'] ? Border.all(color: AppColors.error.withOpacity(0.5)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.noticesColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(notice['category'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.noticesColor)),
          ),
          if (notice['important']) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
              child: const Text('Important', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error)),
            ),
          ],
          const Spacer(),
          Text(_formatDate(notice['date']), style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 10),
        Text(notice['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }
}
