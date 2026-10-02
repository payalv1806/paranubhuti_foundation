import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';
import '/features/home/presentation/screens/home_screen.dart';

enum _LoginMode { phone, email }

/// Login screen with a Phone/Email toggle. Phone sends an OTP (navigates to
/// OtpScreen); Email signs in directly (or offers to create an account if
/// the email doesn't exist yet).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();

  _LoginMode _mode = _LoginMode.phone;
  bool _isSignUp = false; // toggles between "Login" and "Create account" for email mode
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) => setState(() {
    _isLoading = value;
    if (value) _errorMessage = null;
  });

  void _setGoogleLoading(bool value) => setState(() {
    _isGoogleLoading = value;
    if (value) _errorMessage = null;
  });

  Future<void> _onGoogleSignIn() async {
    _setGoogleLoading(true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'popup-closed-by-user' && e.code != 'canceled') {
        setState(() => _errorMessage = _friendlyAuthError(e.code));
      }
    } on FirebaseException catch (e) {
      setState(() => _errorMessage = 'Could not save your profile (${e.code}). Please try again.');
    } catch (e) {
      setState(() => _errorMessage = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) _setGoogleLoading(false);
    }
  }

  Future<void> _onSendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter a valid phone number');
      return;
    }
    _setLoading(true);
    await _authService.sendOtp(
      phoneNumber: _phoneController.text.trim(),
      codeSentCallback: (verificationId) {
        _setLoading(false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OtpScreen()),
        );
      },
      errorCallback: (message) {
        _setLoading(false);
        setState(() => _errorMessage = message);
      },
    );
  }

  Future<void> _onEmailSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty || (_isSignUp && _nameController.text.trim().isEmpty)) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    _setLoading(true);
    try {
      if (_isSignUp) {
        await _authService.signUpWithEmail(
          email: email,
          password: password,
          name: _nameController.text.trim(),
        );
      } else {
        await _authService.signInWithEmail(email: email, password: password);
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyAuthError(e.code));
    } on FirebaseException catch (e) {
      // Covers Firestore errors, e.g. permission-denied from security rules
      setState(() => _errorMessage = 'Could not save your profile (${e.code}). Please try again.');
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email. Try signing up instead.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email. Try logging in instead.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.sectionGap,
          ),
          children: [
            Center(
              child: Container(
                height: 84,
                width: 84,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/Ngo_Logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.volunteer_activism_rounded, size: 44, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text('Welcome to Birthday Cause', style: AppTextStyles.displayLgMobile.copyWith(fontSize: 26), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.unit),
            Text('Log in to register birthdays and track your giving.', style: AppTextStyles.bodyMd, textAlign: TextAlign.center),

            const SizedBox(height: AppSpacing.sectionGap),

            // Phone / Email toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(child: _modeTab('Phone', _LoginMode.phone)),
                  Expanded(child: _modeTab('Email', _LoginMode.email)),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(color: AppColors.surfaceContainerHigh),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter * 1.2),
                child: _mode == _LoginMode.phone ? _buildPhoneForm() : _buildEmailForm(),
              ),
            ),

            const SizedBox(height: AppSpacing.gutter),

            // Google Sign-In Separator
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.outlineVariant.withValues(alpha: 0.6))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: Text(
                    'OR',
                    style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.outlineVariant.withValues(alpha: 0.6))),
              ],
            ),

            const SizedBox(height: AppSpacing.gutter),

            // Sign in with Google Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (_isLoading || _isGoogleLoading) ? null : _onGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.surfaceContainerHighest, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.unit * 1.8,
                  ),
                  elevation: 1,
                  shadowColor: AppColors.cardShadow,
                ),
                child: _isGoogleLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(20, 20),
                            painter: _GoogleLogoPainter(),
                          ),
                          const SizedBox(width: AppSpacing.gutter),
                          Text(
                            'Sign in with Google',
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.gutter),
              Container(
                padding: const EdgeInsets.all(AppSpacing.unit * 1.5),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: AppSpacing.unit),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, _LoginMode mode) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _mode = mode;
        _errorMessage = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.unit * 1.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.buttonText.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PHONE NUMBER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.unit),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+91 98765 43210',
            prefixIcon: Icon(Icons.phone_android_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isLoading || _isGoogleLoading) ? null : _onSendOtp,
            child: _isLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send OTP'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isSignUp) ...[
          Text('NAME', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.unit),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Your name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
        ],
        Text('EMAIL', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.unit),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'you@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
        Text('PASSWORD', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.unit),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),

        const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isLoading || _isGoogleLoading) ? null : _onEmailSubmit,
            child: _isLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isSignUp ? 'Create Account' : 'Log In'),
          ),
        ),

        const SizedBox(height: AppSpacing.gutter),

        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _isSignUp = !_isSignUp;
              _errorMessage = null;
            }),
            child: Text(
              _isSignUp ? 'Already have an account? Log in' : "Don't have an account? Sign up",
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

/// Official 4-color Google "G" brand icon vector painter.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 48.0;

    canvas.save();
    canvas.scale(scale, scale);

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Blue
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20.0)
      ..lineTo(24.0, 20.0)
      ..lineTo(24.0, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..lineTo(39.89, 42.2)
      ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Green
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(24.0, 48.0)
      ..cubicTo(30.48, 48.0, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.24, 38.49, 24.0, 38.49)
      ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
      ..lineTo(2.55, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48.0, 24.0, 48.0)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24.0)
      ..cubicTo(9.77, 22.4, 10.05, 20.86, 10.53, 19.41)
      ..lineTo(2.55, 13.22)
      ..cubicTo(0.92, 16.46, 0.0, 20.12, 0.0, 24.0)
      ..cubicTo(0.0, 27.88, 0.92, 31.54, 2.55, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Red
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(24.0, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0.0, 24.0, 0.0)
      ..cubicTo(14.62, 0.0, 6.51, 5.38, 2.55, 13.22)
      ..lineTo(10.53, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24.0, 9.5)
      ..close();
    canvas.drawPath(redPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}