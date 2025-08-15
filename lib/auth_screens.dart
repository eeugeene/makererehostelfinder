import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _managerMode = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2E7D32).withValues(alpha: 0.05),
              const Color(0xFF1976D2).withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo and title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    _managerMode ? Icons.business : Icons.home_outlined,
                    size: 60,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _managerMode ? 'Hostel Manager Portal' : 'Makerere Hostel Finder',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _managerMode 
                    ? 'Manage your hostel listings and bookings'
                    : 'Find your perfect hostel near campus',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Manager/Student mode toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false, 
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school, size: 18),
                            const SizedBox(width: 8),
                            Text('Student'),
                          ],
                        ),
                      ),
                      ButtonSegment(
                        value: true, 
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business, size: 18),
                            const SizedBox(width: 8),
                            Text('Manager'),
                          ],
                        ),
                      ),
                    ],
                    selected: {_managerMode},
                    onSelectionChanged: (s) => setState(() => _managerMode = s.first),
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      selectedBackgroundColor: const Color(0xFF2E7D32),
                      selectedForegroundColor: Colors.white,
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Form fields
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_isSignUp) ...[
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline, color: const Color(0xFF2E7D32)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFF2E7D32)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFF2E7D32)),
                        ),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Submit button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Create Account' : 'Sign In',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Toggle sign up/sign in
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Don\'t have an account? Sign Up',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                if (!_managerMode) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Google sign in for students
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(Icons.g_mobiledata, size: 24),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ));
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (_isSignUp && name.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      
      final role = _managerMode ? 'manager' : 'student';
      if (_isSignUp) {
        await authService.signUpWithEmail(email, password, name, role);
        await authService.syncCurrentUserProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
        }
      } else {
        await authService.signInWithEmail(email, password);
        await authService.syncCurrentUserProfile();
        // If manager mode selected on login, force-set role to manager for this session/profile
        if (_managerMode) {
          await authService.forceSetRole('manager');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        _showError('Google sign-in failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
