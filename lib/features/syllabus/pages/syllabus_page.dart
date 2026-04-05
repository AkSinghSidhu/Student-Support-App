import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/search_bar_widget.dart';
import '../../../shared/widgets/shimmer_loader.dart';

/// Syllabus viewer page with semester and subject selection.
class SyllabusPage extends StatefulWidget {
  const SyllabusPage({super.key});

  @override
  State<SyllabusPage> createState() => _SyllabusPageState();
}

class _SyllabusPageState extends State<SyllabusPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  
  int _selectedSemester = 1;
  String? _selectedSubject;
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Sample data - will be replaced by Firebase
  final Map<int, List<Map<String, dynamic>>> _syllabusData = {
    1: [
      {'code': 'CS101', 'name': 'Programming Fundamentals', 'credits': 4},
      {'code': 'MA101', 'name': 'Engineering Mathematics I', 'credits': 4},
      {'code': 'PH101', 'name': 'Engineering Physics', 'credits': 3},
      {'code': 'EN101', 'name': 'Technical Communication', 'credits': 2},
    ],
    2: [
      {'code': 'CS102', 'name': 'Data Structures', 'credits': 4},
      {'code': 'MA102', 'name': 'Engineering Mathematics II', 'credits': 4},
      {'code': 'CS103', 'name': 'Object Oriented Programming', 'credits': 3},
    ],
    3: [
      {'code': 'CS201', 'name': 'Algorithms', 'credits': 4},
      {'code': 'CS202', 'name': 'Database Systems', 'credits': 4},
      {'code': 'CS203', 'name': 'Operating Systems', 'credits': 4},
    ],
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _selectedSemester = 1;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        appBar: const CustomAppBar(title: 'Syllabus'),
        body: ShimmerLoader(
          isDarkMode: isDarkMode,
          child: ListView.builder(
            itemCount: 4,
            itemBuilder: (_, __) => ShimmerCard(height: 70, isDarkMode: isDarkMode),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: const CustomAppBar(title: 'Syllabus'),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            SearchBarWidget(
              controller: _searchController,
              hint: 'Search subjects...',
              isDarkMode: isDarkMode,
            ),
            // Semester selector
            _buildSemesterSelector(isDarkMode),
            // Subject list
            Expanded(child: _buildSubjectList(isDarkMode)),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterSelector(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(6),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(8, (index) {
            final sem = index + 1;
            final isSelected = _selectedSemester == sem;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSemester = sem;
                  _selectedSubject = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.syllabusColor
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Sem $sem',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primaryWhite
                        : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSubjectList(bool isDarkMode) {
    final List<Map<String, dynamic>> allSubjects = _syllabusData[_selectedSemester] ?? [];
    final subjects = allSubjects.where((s) {
      if (_searchQuery.isEmpty) return true;
      final name = (s['name'] as String).toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
    
    if (subjects.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No syllabus available',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primaryDarkBlue,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final isExpanded = _selectedSubject == subject['code'];
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExpanded
                  ? AppColors.syllabusColor.withValues(alpha: 0.5)
                  : AppColors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlack.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSubject = isExpanded ? null : subject['code'];
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.syllabusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subject['code'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.syllabusColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${subject['credits']} Credits',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryDarkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subject['name'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        'Syllabus content will be loaded from Firebase. Tap to view detailed topics, units, and course objectives.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
      ),
    );
  }
}
