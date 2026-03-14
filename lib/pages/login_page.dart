import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/database_service.dart';
import '../core/app_constants.dart';

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

  static const Color primaryDarkBlue = Color(0xFF020065);
  static const Color primaryBlack = Color(0xFF000000);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color primaryGold = Color(0xFFFDC50C);

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

  final DatabaseReference _database = DatabaseService.db;

  // FIX: Load saved AUID and Remember Me state on app open
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe) {
      final savedAuid = prefs.getString('logged_in_auid') ?? '';
      setState(() {
        _rememberMe = true;
        _auidController.text = savedAuid;
      });
    }
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final enteredAuid = _auidController.text.trim();
      final enteredPassword = _passwordController.text;

      try {
        // FIX: Try 'users' first, then fall back to 'students'
        DataSnapshot snapshot = await _database.child('users').child(enteredAuid).get();

        if (!snapshot.exists) {
          snapshot = await _database.child('students').child(enteredAuid).get();
        }

        if (snapshot.exists) {
          // FIX: Safe type check — Firebase may return String instead of Map
          final rawValue = snapshot.value;

          if (rawValue is! Map) {
            setState(() => _isLoading = false);
            _showErrorSnackBar('Invalid data format in database. Contact admin.');
            return;
          }

          final userData = Map<String, dynamic>.from(rawValue);
          final storedPassword = userData['password']?.toString();

          if (storedPassword != null && storedPassword == enteredPassword) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('logged_in_auid', enteredAuid);

            // FIX: Actually save/clear Remember Me based on checkbox state
            await prefs.setBool('remember_me', _rememberMe);

            // Attendance alerts are now handled by the background service
            // (scheduled daily check at 6 PM), no per-login listener needed.

            setState(() => _isLoading = false);

            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            setState(() => _isLoading = false);
            _showErrorSnackBar('Incorrect password. Please try again.');
          }
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackBar('No user found with this AUID.');
        }
      } catch (e) {
        setState(() => _isLoading = false);

        // FIX: Show actual helpful error instead of generic message
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('permission') || errorStr.contains('denied')) {
          _showErrorSnackBar('Access denied. Contact admin to check Firebase rules.');
        } else if (errorStr.contains('network') ||
            errorStr.contains('socket') ||
            errorStr.contains('failed host lookup')) {
          _showErrorSnackBar('No internet connection. Please try again.');
        } else if (errorStr.contains('timeout')) {
          _showErrorSnackBar('Connection timed out. Please try again.');
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
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
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
            colors: [primaryDarkBlue, Color(0xFF010033), primaryBlack],
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
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildLoginCard(),
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

  Widget _buildHeader() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardBackgroundDark : primaryWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDarkMode ? [] : [
              BoxShadow(color: primaryGold.withOpacity(0.4), blurRadius: 24, spreadRadius: 3),
              BoxShadow(color: primaryDarkBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: Icon(Icons.school_rounded, size: 40, color: isDarkMode ? primaryGold : primaryDarkBlue),
        ),
        const SizedBox(height: 20),
        const Text(
          'Welcome Back',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryWhite, letterSpacing: 1.0),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue your journey',
          style: TextStyle(fontSize: 13, color: primaryWhite.withOpacity(0.7), letterSpacing: 0.4),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : primaryWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(color: primaryBlack.withOpacity(0.2), blurRadius: 32, offset: const Offset(0, 16)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputLabel('AUID Number', isDarkMode),
            const SizedBox(height: 6),
            _buildAuidField(isDarkMode),
            const SizedBox(height: 14),
            _buildInputLabel('Password', isDarkMode),
            const SizedBox(height: 6),
            _buildPasswordField(isDarkMode),
            const SizedBox(height: 10),
            _buildRememberForgotRow(isDarkMode),
            const SizedBox(height: 18),
            _buildLoginButton(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isDarkMode) {
    return Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDarkMode ? AppColors.textPrimaryDark : primaryDarkBlue, letterSpacing: 0.4),
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
      style: TextStyle(fontSize: 14, color: isDarkMode ? AppColors.textPrimaryDark : primaryBlack, letterSpacing: 1.5),
      decoration: InputDecoration(
        hintText: 'Enter your 9-digit AUID',
        hintStyle: TextStyle(color: (isDarkMode ? AppColors.textPrimaryDark : primaryBlack).withOpacity(0.4), fontSize: 13, letterSpacing: 0.5),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: (isDarkMode ? primaryGold : primaryDarkBlue).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(Icons.badge_outlined, color: isDarkMode ? primaryGold : primaryDarkBlue, size: 16),
        ),
        filled: true,
        fillColor: isDarkMode ? AppColors.surfaceDark : primaryDarkBlue.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryGold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your AUID';
        if (value.length != 9) return 'AUID must be exactly 9 digits';
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(fontSize: 14, color: isDarkMode ? AppColors.textPrimaryDark : primaryBlack),
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: TextStyle(color: (isDarkMode ? AppColors.textPrimaryDark : primaryBlack).withOpacity(0.4), fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: (isDarkMode ? primaryGold : primaryDarkBlue).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(Icons.lock_outline_rounded, color: isDarkMode ? primaryGold : primaryDarkBlue, size: 16),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: (isDarkMode ? primaryGold : primaryDarkBlue).withOpacity(0.6),
            size: 18,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: isDarkMode ? AppColors.surfaceDark : primaryDarkBlue.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryGold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your password';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildRememberForgotRow(bool isDarkMode) {
    final textColor = isDarkMode ? AppColors.textSecondaryDark : primaryBlack.withOpacity(0.7);
    final actionColor = isDarkMode ? primaryGold : primaryDarkBlue;
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
                activeColor: primaryGold,
                checkColor: primaryDarkBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: BorderSide(color: actionColor.withOpacity(0.4), width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text('Remember me', style: TextStyle(fontSize: 11, color: textColor)),
          ],
        ),

        // FIX: Forgot Password is no longer a dead button
        TextButton(
          onPressed: () => _showErrorSnackBar('Contact admin to reset your password.'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot Password?',
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
          backgroundColor: primaryGold,
          foregroundColor: primaryDarkBlue,
          disabledBackgroundColor: primaryGold.withOpacity(0.6),
          elevation: 0,
          shadowColor: primaryGold.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: primaryDarkBlue),
        )
            : const Text(
          'Sign In',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.6),
        ),
      ),
    );
  }
}