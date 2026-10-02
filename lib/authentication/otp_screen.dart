import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '/features/home/presentation/screens/home_screen.dart';

/// OTP verification screen — shown after LoginScreen sends an SMS code.
/// On success, navigates to HomeScreen (AuthGate in main.dart will also
/// pick up the sign-in automatically, so this is a belt-and-braces nav).
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authService = AuthService();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _onVerify() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code sent to your phone');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.verifyOtp(code);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (_) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'That code is incorrect. Please check and try again.';
      case 'session-expired':
        return 'This code has expired. Go back and request a new one.';
      default:
        return 'Verification failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.unit * 2,
          ),
          children: [
            const Text('🔐', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.gutter),
            Text('Verify your number', style: AppTextStyles.displayLgMobile.copyWith(fontSize: 26)),
            const SizedBox(height: AppSpacing.unit),
            Text(
              "Enter the 6-digit code we just sent you via SMS.",
              style: AppTextStyles.bodyMd,
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            Text('VERIFICATION CODE', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.unit),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd.copyWith(letterSpacing: 8),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '••••••',
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.gutter),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: AppSpacing.sectionGap),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onVerify,
                child: _isLoading
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Verify & Continue'),
              ),
            ),

            const SizedBox(height: AppSpacing.gutter),

            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                  // Go back to LoginScreen so the user can resend
                  // via _onSendOtp again with the same phone number.
                  Navigator.pop(context);
                },
                child: Text(
                  "Didn't get a code? Go back and resend",
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}