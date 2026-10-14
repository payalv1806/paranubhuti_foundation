import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/home_screen.dart';
import 'package:paranubhutifoundation/services/certificate_service.dart';
import 'certificate_view_screen.dart';

/// Thank You screen — shown after a successful verified Razorpay payment.
/// Confirms the donation, provides direct access to view/download the donation
/// certificate, and routes back to Home.
class ThankYouScreen extends StatefulWidget {
  final String causeTitle;
  final double amount;
  final bool anonymous;
  final String? donationId;

  const ThankYouScreen({
    super.key,
    required this.causeTitle,
    required this.amount,
    required this.anonymous,
    this.donationId,
  });

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  bool _isLoadingCert = false;

  Future<void> _openCertificate() async {
    final donationId = widget.donationId;
    if (donationId == null) return;

    setState(() => _isLoadingCert = true);
    try {
      final cert = await CertificateService().generateOrGetCertificate(donationId);
      if (!mounted) return;
      if (cert != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CertificateViewScreen(certificate: cert)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load certificate: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingCert = false);
    }
  }

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
                child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              Text(
                'Thank You!',
                style: AppTextStyles.displayLgMobile.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                'Your gift of ₹${widget.amount.toStringAsFixed(0)} to ${widget.causeTitle} is making a real difference.',
                style: AppTextStyles.bodyMd,
                textAlign: TextAlign.center,
              ),

              if (widget.anonymous) ...[
                const SizedBox(height: AppSpacing.gutter),
                Text(
                  "You've chosen to donate anonymously — your name won't be shown publicly.",
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.sectionGap),

              // Certificate Action Card
              if (widget.donationId != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Donation Certificate Ready',
                                  style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Your verified donation certificate has been generated.',
                                  style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingCert ? null : _openCertificate,
                          icon: _isLoadingCert
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: const Text('View & Download Certificate'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],

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