import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/notification_service.dart';

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

  // Custom colors from the provided palette
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _auidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Firebase Database reference with correct regional URL
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://studentsupporttest-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final enteredAuid = _auidController.text.trim();
      final enteredPassword = _passwordController.text;
      
      try {
        // Query Firebase Realtime Database for the user
        final snapshot = await _database.child('users').child(enteredAuid).get();
        
        if (snapshot.exists) {
          final userData = Map<String, dynamic>.from(snapshot.value as Map);
          final storedPassword = userData['password'] as String?;
          
          if (storedPassword != null && storedPassword == enteredPassword) {
            // Always save AUID for current session (home page needs it)
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('logged_in_auid', enteredAuid);
            
            // Start real-time attendance monitoring
            NotificationService().startAttendanceListener(enteredAuid);
            
            // If Remember Me is not checked, we'll clear it on logout
            // For now, just save it so home page can fetch user data
            
            setState(() => _isLoading = false);
            
            // Navigate to home page on successful login
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
        _showErrorSnackBar('An error occurred. Please check your connection.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryDarkBlue,
              Color(0xFF010033),
              primaryBlack,
            ],
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
                      // Logo and Welcome Section
                      _buildHeader(),
                      const SizedBox(height: 32),
                      
                      // Login Card
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
    return Column(
      children: [
        // Animated Logo Container
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: primaryWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primaryGold.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: primaryDarkBlue.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 40,
            color: primaryDarkBlue,
          ),
        ),
        const SizedBox(height: 20),
        
        // Welcome Text
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: primaryWhite,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue your journey',
          style: TextStyle(
            fontSize: 13,
            color: primaryWhite.withOpacity(0.7),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryBlack.withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AUID Field
            _buildInputLabel('AUID Number'),
            const SizedBox(height: 6),
            _buildAuidField(),
            const SizedBox(height: 14),
            
            // Password Field
            _buildInputLabel('Password'),
            const SizedBox(height: 6),
            _buildPasswordField(),
            const SizedBox(height: 12),
            
            // Remember Me & Forgot Password Row
            _buildRememberForgotRow(),
            const SizedBox(height: 20),
            
            // Login Button
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: primaryDarkBlue,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildAuidField() {
    return TextFormField(
      controller: _auidController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      style: const TextStyle(
        fontSize: 14,
        color: primaryBlack,
        letterSpacing: 1.5,
      ),
      decoration: InputDecoration(
        hintText: 'Enter your 9-digit AUID',
        hintStyle: TextStyle(
          color: primaryBlack.withOpacity(0.4),
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryDarkBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.badge_outlined,
            color: primaryDarkBlue,
            size: 16,
          ),
        ),
        filled: true,
        fillColor: primaryDarkBlue.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: primaryGold,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your AUID';
        }
        if (value.length != 9) {
          return 'AUID must be exactly 9 digits';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(
        fontSize: 14,
        color: primaryBlack,
      ),
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: TextStyle(
          color: primaryBlack.withOpacity(0.4),
          fontSize: 13,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryDarkBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: primaryDarkBlue,
            size: 16,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword 
                ? Icons.visibility_off_outlined 
                : Icons.visibility_outlined,
            color: primaryDarkBlue.withOpacity(0.6),
            size: 18,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        filled: true,
        fillColor: primaryDarkBlue.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: primaryGold,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me
        Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() => _rememberMe = value!);
                },
                activeColor: primaryGold,
                checkColor: primaryDarkBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: primaryDarkBlue.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Remember me',
              style: TextStyle(
                fontSize: 11,
                color: primaryBlack.withOpacity(0.7),
              ),
            ),
          ],
        ),
        
        // Forgot Password
        TextButton(
          onPressed: () {
            // Handle forgot password
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primaryDarkBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryDarkBlue,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
      ),
    );
  }
}
