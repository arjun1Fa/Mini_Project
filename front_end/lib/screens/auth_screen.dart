import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    if (!_isLogin && name.isEmpty) {
      _showError('Please provide your full name.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authServiceProvider);
      if (_isLogin) {
        await auth.signIn(email: email, password: password);
      } else {
        await auth.signUp(email: email, password: password, fullName: name);
        // Signup usually auto-logs you in if email confirmations are disabled.
      }
      
      // If success, user will automatically receive a new auth session event
      // handled globally. We can also manually push to shell if needed.
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred: \$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppColors.amber,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // App Logo or Icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.leaf,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                _isLogin ? 'Welcome Back' : 'Join NutriLens',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 32,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Log in to continue tracking your nutrition.'
                    : 'Create an account to start your journey.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 48),

              // Form Fields
              if (!_isLogin) ...[
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),
              ],
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passCtrl,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 32),

              // Submit Button
              NvPrimaryButton(
                label: _isLogin ? 'Log In' : 'Sign Up',
                onPressed: _isLoading ? () {} : _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),

              // Toggle Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? "Don't have an account?" : "Already have an account?",
                    style: GoogleFonts.dmSans(color: AppColors.inkMuted),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _emailCtrl.clear();
                        _passCtrl.clear();
                        _nameCtrl.clear();
                      });
                    },
                    child: Text(
                      _isLogin ? 'Sign Up' : 'Log In',
                      style: GoogleFonts.dmSans(
                        color: AppColors.leaf,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(color: AppColors.inkMuted),
        prefixIcon: Icon(icon, color: AppColors.inkMuted),
        filled: true,
        fillColor: AppColors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.leaf, width: 2),
        ),
      ),
    );
  }
}
