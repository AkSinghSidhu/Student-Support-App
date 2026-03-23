import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_overlay.dart';

/// Resources page with tabs for Books, Notes, and PYQs.
class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Sample data - will be replaced by Firebase
  final List<Map<String, dynamic>> _books = [
    {'title': 'Data Structures & Algorithms', 'author': 'Cormen et al.', 'type': 'PDF'},
    {'title': 'Database System Concepts', 'author': 'Silberschatz', 'type': 'PDF'},
    {'title': 'Operating System Concepts', 'author': 'Galvin', 'type': 'PDF'},
  ];

  final List<Map<String, dynamic>> _notes = [
    {'title': 'CS201 - Unit 1 Notes', 'subject': 'Algorithms', 'pages': 25},
    {'title': 'CS202 - Complete Notes', 'subject': 'DBMS', 'pages': 80},
    {'title': 'CS203 - Mid Exam Notes', 'subject': 'OS', 'pages': 40},
  ];

  final List<Map<String, dynamic>> _pyqs = [
    {'title': 'CS201 Mid Exam 2025', 'year': '2025', 'semester': 'Mid'},
    {'title': 'CS201 End Exam 2024', 'year': '2024', 'semester': 'End'},
    {'title': 'CS202 Mid Exam 2025', 'year': '2025', 'semester': 'Mid'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: const CustomAppBar(title: 'Resources'),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // Tab bar
            _buildTabBar(isDarkMode),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildResourceList(_books, 'book', isDarkMode),
                  _buildResourceList(_notes, 'note', isDarkMode),
                  _buildResourceList(_pyqs, 'pyq', isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
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
          color: AppColors.resourcesColor,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: AppColors.primaryWhite,
        unselectedLabelColor: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Books'),
          Tab(text: 'Notes'),
          Tab(text: 'PYQs'),
        ],
      ),
    );
  }

  Widget _buildResourceList(List<Map<String, dynamic>> items, String type, bool isDarkMode) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'No resources available',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildResourceCard(items[index], type, isDarkMode);
      },
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> item, String type, bool isDarkMode) {
    IconData icon;
    Color color;
    String subtitle;

    switch (type) {
      case 'book':
        icon = Icons.book_outlined;
        color = const Color(0xFF6366F1);
        subtitle = 'by ${item['author']}';
        break;
      case 'note':
        icon = Icons.description_outlined;
        color = const Color(0xFF10B981);
        subtitle = '${item['subject']} • ${item['pages']} pages';
        break;
      case 'pyq':
        icon = Icons.quiz_outlined;
        color = const Color(0xFFF97316);
        subtitle = '${item['year']} ${item['semester']} Exam';
        break;
      default:
        icon = Icons.folder_outlined;
        color = AppColors.resourcesColor;
        subtitle = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening ${item['title']}...'),
                backgroundColor: AppColors.primaryDarkBlue,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.download_outlined,
                    color: AppColors.primaryDarkBlue,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
