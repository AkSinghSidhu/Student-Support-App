import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/services/cache_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/queue_service.dart';
import '../../../core/database_service.dart';
import '../../../core/app_constants.dart';

/// Complaint submission page with form for reporting issues.
class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Academic';
  String _urgency = 'Medium';
  bool _isSubmitting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _types = [
    'Academic',
    'Infrastructure',
    'Hostel',
    'Canteen',
    'Transport',
    'Other',
  ];

  final List<Map<String, dynamic>> _urgencyLevels = [
    {'label': 'Low', 'color': AppColors.success},
    {'label': 'Medium', 'color': AppColors.warning},
    {'label': 'High', 'color': AppColors.error},
  ];

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
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final auid = prefs.getString('logged_in_auid');

        if (auid == null) {
          throw Exception('User not logged in');
        }

        final complaintData = {
          'userId': auid,
          'subject': _subjectController.text.trim(),
          'description': _descriptionController.text.trim(),
          'type': _selectedType,
          'urgency': _urgency,
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        };

        // Check connectivity
        final connectivityResult = await Connectivity().checkConnectivity();
        final isOnline = !connectivityResult.contains(ConnectivityResult.none);

        if (isOnline) {
          final database = DatabaseService.db;
          final complaintRef = database.child('complaints').child(auid).push();
          
          await complaintRef.set(complaintData).timeout(const Duration(seconds: 5));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Complaint registered successfully!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          // Offline - Add to Queue
          await QueueService.addToQueue('complaint', auid, complaintData);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: const CustomAppBar(title: 'Register Complaint'),
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
                
                // Complaint type
                _buildSectionLabel('Complaint Type', isDarkMode),
                const SizedBox(height: 10),
                _buildTypeSelector(isDarkMode),
                const SizedBox(height: 24),
                
                // Urgency level
                _buildSectionLabel('Urgency Level', isDarkMode),
                const SizedBox(height: 10),
                _buildUrgencySelector(isDarkMode),
                const SizedBox(height: 24),
                
                // Subject
                _buildSectionLabel('Subject', isDarkMode),
                const SizedBox(height: 10),
                _buildSubjectInput(isDarkMode),
                const SizedBox(height: 20),
                
                // Description
                _buildSectionLabel('Description', isDarkMode),
                const SizedBox(height: 10),
                _buildDescriptionInput(isDarkMode),
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

  Widget _buildHeaderCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.complaintColor.withOpacity(0.15),
            AppColors.complaintColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.complaintColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.complaintColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.report_problem_outlined,
              color: AppColors.complaintColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report an Issue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll address your concerns promptly',
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

  Widget _buildTypeSelector(bool isDarkMode) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _types.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
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
              type,
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

  Widget _buildUrgencySelector(bool isDarkMode) {
    return Row(
      children: _urgencyLevels.map((level) {
        final isSelected = _urgency == level['label'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _urgency = level['label']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: level == _urgencyLevels.last ? 0 : 10,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (level['color'] as Color).withOpacity(0.15)
                    : (isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? level['color'] as Color
                      : (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight).withOpacity(0.3),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  level['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? level['color'] as Color
                        : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectInput(bool isDarkMode) {
    return TextFormField(
      controller: _subjectController,
      style: TextStyle(fontSize: 14, color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: 'Brief subject of complaint',
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
          return 'Please enter a subject';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionInput(bool isDarkMode) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 5,
      style: TextStyle(fontSize: 14, color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: 'Describe the issue in detail...',
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
          return 'Please describe the issue';
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
        onPressed: _isSubmitting ? null : _submitComplaint,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.complaintColor,
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
                'Submit Complaint',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
