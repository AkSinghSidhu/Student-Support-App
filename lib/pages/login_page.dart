import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../core/theme/theme_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/repositories/auth_repository.dart';
import '../core/di/service_locator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _auidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    _loadRememberMe(); // FIX: Load saved AUID if Remember Me was checked
  }

  @override
  void dispose() {
    _animationController.dispose();
    _auidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // FIX: Load saved AUID and Remember Me state on app open
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(AppConstants.rememberMeKey) ?? false;
    if (rememberMe) {
      final savedAuid = prefs.getString(AppConstants.auidKey) ?? '';
      if (mounted) {
        setState(() {
          _rememberMe = true;
          _auidController.text = savedAuid;
        });
      }
    }
  }

  final _authRepo = sl<AuthRepository>();

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final enteredAuid = _auidController.text.trim();
      final enteredPassword = _passwordController.text;

      try {
        final user = await _authRepo.login(enteredAuid, enteredPassword);

        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConstants.rememberMeKey, _rememberMe);

          if (!mounted) return;
          setState(() => _isLoading = false);

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showErrorSnackBar(AppConstants.loginErrorInvalid);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        // FIX: Show actual helpful error instead of generic message
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('permission') || errorStr.contains('denied')) {
          _showErrorSnackBar(AppConstants.loginErrorPermission);
        } else if (errorStr.contains('network') ||
            errorStr.contains('socket') ||
            errorStr.contains('failed host lookup')) {
          _showErrorSnackBar(AppConstants.loginErrorNetwork);
        } else if (errorStr.contains('timeout')) {
          _showErrorSnackBar(AppConstants.loginErrorTimeout);
        } else {
          _showErrorSnackBar('Login failed: $e');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: AppColors.primaryWhite)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: AppSpacing.paddingMd,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? null : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDarkBlue, AppColors.gradientMiddle, AppColors.primaryBlack],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(context, isDarkMode),
                      AppSpacing.verticalXl,
                      _buildLoginCard(context, isDarkMode),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.primaryWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDarkMode ? [] : [
              BoxShadow(color: AppColors.primaryGold.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 3),
              BoxShadow(color: AppColors.primaryDarkBlue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: Icon(Icons.school_rounded, size: 40, color: isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue),
        ),
        AppSpacing.verticalLg,
        Text(
          AppConstants.loginWelcomeTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryWhite, letterSpacing: 1.0),
        ),
        AppSpacing.verticalSm,
        Text(
          AppConstants.loginSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13, color: AppColors.primaryWhite.withValues(alpha: 0.7), letterSpacing: 0.4),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(color: AppColors.primaryBlack.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, 16)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputLabel(context, AppConstants.loginAuidLabel, isDarkMode),
            AppSpacing.verticalSm,
            _buildAuidField(isDarkMode),
            const SizedBox(height: 14),
            _buildInputLabel(context, AppConstants.loginPasswordLabel, isDarkMode),
            AppSpacing.verticalSm,
            _buildPasswordField(isDarkMode),
            const SizedBox(height: 10),
            _buildRememberForgotRow(isDarkMode),
            AppSpacing.verticalMd,
            _buildLoginButton(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(BuildContext context, String label, bool isDarkMode) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primaryDarkBlue, letterSpacing: 0.4),
    );
  }

  Widget _buildAuidField(bool isDarkMode) {
    return TextFormField(
      controller: _auidController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      style: TextStyle(fontSize: 14, color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primaryBlack, letterSpacing: 1.5),
      decoration: InputDecoration(
        hintText: AppConstants.loginAuidHint,
        hintStyle: TextStyle(color: (isDarkMode ? AppColors.textPrimaryDark : AppColors.primaryBlack).withValues(alpha: 0.4), fontSize: 13, letterSpacing: 0.5),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: (isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(Icons.badge_outlined, color: isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue, size: 16),
        ),
        filled: true,
        fillColor: isDarkMode ? AppColors.surfaceDark : AppColors.primaryDarkBlue.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return AppConstants.loginAuidEmpty;
        if (value.length != 9) return AppConstants.loginAuidLengthError;
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(fontSize: 14, color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primaryBlack),
      decoration: InputDecoration(
        hintText: AppConstants.loginPasswordHint,
        hintStyle: TextStyle(color: (isDarkMode ? AppColors.textPrimaryDark : AppColors.primaryBlack).withValues(alpha: 0.4), fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: (isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(Icons.lock_outline_rounded, color: isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue, size: 16),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: (isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue).withValues(alpha: 0.6),
            size: 18,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: isDarkMode ? AppColors.surfaceDark : AppColors.primaryDarkBlue.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return AppConstants.loginPasswordEmpty;
        if (value.length < 6) return AppConstants.loginPasswordLengthError;
        return null;
      },
    );
  }

  Widget _buildRememberForgotRow(bool isDarkMode) {
    final textColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.primaryBlack.withValues(alpha: 0.7);
    final actionColor = isDarkMode ? AppColors.primaryGold : AppColors.primaryDarkBlue;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) => setState(() => _rememberMe = value!),
                activeColor: AppColors.primaryGold,
                checkColor: AppColors.primaryDarkBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: BorderSide(color: actionColor.withValues(alpha: 0.4), width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(AppConstants.loginRememberMe, style: TextStyle(fontSize: 11, color: textColor)),
          ],
        ),

        // FIX: Forgot Password is no longer a dead button
        TextButton(
          onPressed: () => _showErrorSnackBar(AppConstants.loginErrorAdminContact),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppConstants.loginForgotPasswordBtn,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: actionColor),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isDarkMode) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: AppColors.primaryDarkBlue,
          disabledBackgroundColor: AppColors.primaryGold.withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: AppColors.primaryGold.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDarkBlue),
        )
            : const Text(
          AppConstants.loginSignInBtn,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.6),
        ),
      ),
    );
  }
}