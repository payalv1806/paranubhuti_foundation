import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/home_screen.dart';

/// Thank You screen — shown after a successful Razorpay payment.
/// Confirms the donation, then routes back to Home (clearing the whole
/// donate → payment → thank-you stack, so back-navigation doesn't replay
/// the payment flow).
class ThankYouScreen extends StatelessWidget {
  final String causeTitle;
  final double amount;
  final bool anonymous;

  const ThankYouScreen({
    super.key,
    required this.causeTitle,
    required this.amount,
    required this.anonymous,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite_rounded, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              Text(
                'Thank You!',
                style: AppTextStyles.displayLgMobile.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                'Your gift of ₹${amount.toStringAsFixed(0)} to $causeTitle is making a real difference.',
                style: AppTextStyles.bodyMd,
                textAlign: TextAlign.center,
              ),

              if (anonymous) ...[
                const SizedBox(height: AppSpacing.gutter),
                Text(
                  "You've chosen to donate anonymously — your name won't be shown publicly.",
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.sectionGap + AppSpacing.unit),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                    );
                  },
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}