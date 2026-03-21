import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/helpers/form_submission_helper.dart';

/// Feedback submission page with form for user feedback.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  String _selectedCategory = 'General';
  String? _selectedDepartment;
  String? _selectedTeacher;
  int _rating = 0;
  bool _isSubmitting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _categories = [
    'General',
    'Academic',
    'Infrastructure',
    'Faculty',
    'Events',
    'Other',
  ];

  final Map<String, List<String>> _departmentTeachers = {
    'Computer Science': [
      'Dr. Alan Turing',
      'Prof. Ada Lovelace',
      'Dr. Grace Hopper',
      'Prof. Donald Knuth',
    ],
    'Electronics': [
      'Dr. Nikola Tesla',
      'Prof. Heinrich Hertz',
      'Dr. John Bardeen',
      'Prof. Thomas Edison',
    ],
    'Mechanical': [
      'Dr. Isaac Newton',
      'Prof. James Watt',
      'Dr. Rudolf Diesel',
      'Prof. Nikolaus Otto',
    ],
    'Civil': [
      'Dr. John Smeaton',
      'Prof. Gustave Eiffel',
      'Dr. Karl Terzaghi',
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
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate() && _rating > 0) {
      if (_selectedDepartment == null) {
        _showError('Please select a department');
        return;
      }
      if (_selectedTeacher == null) {
        _showError('Please select a teacher');
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final prefs = await SharedPreferences.getInstance();
        final auid = prefs.getString('logged_in_auid');

        if (auid == null) {
          throw Exception('User not logged in');
        }

        final feedbackData = {
          'userId': auid,
          'department': _selectedDepartment,
          'teacher': _selectedTeacher,
          'category': _selectedCategory,
          'rating': _rating,
          'message': _feedbackController.text.trim(),
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        };

        final submitted = await FormSubmissionHelper.submitForm(
          type: 'feedback',
          auid: auid,
          data: feedbackData,
        );
        
        if (submitted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Feedback submitted successfully!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('No internet — saved as draft, will send automatically when you reconnect'),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    } else if (_rating == 0) {
       _showError('Please select a rating');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: const CustomAppBar(title: 'Feedback'),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                _buildHeaderCard(isDarkMode),
                const SizedBox(height: 24),

                // Department Selector
                _buildSectionLabel('Department', isDarkMode),
                const SizedBox(height: 10),
                _buildDepartmentDropdown(isDarkMode),
                const SizedBox(height: 24),
                
                // Teacher Selector (Dependent)
                // Only show if department is selected
                if (_selectedDepartment != null) ...[
                  _buildSectionLabel('Teacher', isDarkMode),
                  const SizedBox(height: 10),
                  _buildTeacherDropdown(isDarkMode),
                  const SizedBox(height: 24),
                ],
                
                // Category selector
                _buildSectionLabel('Category', isDarkMode),
                const SizedBox(height: 10),
                _buildCategorySelector(isDarkMode),
                const SizedBox(height: 24),
                
                // Rating
                _buildSectionLabel('Rating', isDarkMode),
                const SizedBox(height: 10),
                _buildRatingSelector(isDarkMode),
                const SizedBox(height: 24),
                
                // Feedback text
                _buildSectionLabel('Your Feedback', isDarkMode),
                const SizedBox(height: 10),
                _buildFeedbackInput(isDarkMode),
                const SizedBox(height: 32),
                
                // Submit button
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDepartment,
          hint: Text(
            'Select Department',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          isExpanded: true,
          dropdownColor: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          items: _departmentTeachers.keys.map((String department) {
            return DropdownMenuItem<String>(
              value: department,
              child: Text(
                department,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedDepartment = newValue;
              _selectedTeacher = null; // Reset teacher when department changes
            });
          },
        ),
      ),
    );
  }

  Widget _buildTeacherDropdown(bool isDarkMode) {
    final teachers = _departmentTeachers[_selectedDepartment] ?? [];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTeacher,
          hint: Text(
            'Select Teacher',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          isExpanded: true,
          dropdownColor: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          items: teachers.map((String teacher) {
            return DropdownMenuItem<String>(
              value: teacher,
              child: Text(
                teacher,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedTeacher = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.feedbackColor.withOpacity(0.15),
            AppColors.feedbackColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.feedbackColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.feedbackColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.feedback_outlined,
              color: AppColors.feedbackColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Your Thoughts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Help us improve your experience',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDarkMode) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildCategorySelector(bool isDarkMode) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryDarkBlue
                  : (isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryDarkBlue
                    : (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withOpacity(0.3),
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryWhite
                    : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingSelector(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        final isSelected = index < _rating;
        return GestureDetector(
          onTap: () => setState(() => _rating = index + 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isSelected ? AppColors.primaryGold : (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight),
              size: 36,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeedbackInput(bool isDarkMode) {
    return TextFormField(
      controller: _feedbackController,
      maxLines: 5,
      style: TextStyle(fontSize: 14, color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: 'Write your feedback here...',
        hintStyle: TextStyle(color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        filled: true,
        fillColor: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withOpacity(0.3),
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your feedback';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.feedbackColor,
          foregroundColor: AppColors.primaryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryWhite,
                ),
              )
            : const Text(
                'Submit Feedback',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
