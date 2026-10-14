import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/models/certificate_model.dart';
import 'package:paranubhutifoundation/services/certificate_service.dart';

class CertificateViewScreen extends StatefulWidget {
  final CertificateModel certificate;

  const CertificateViewScreen({super.key, required this.certificate});

  @override
  State<CertificateViewScreen> createState() => _CertificateViewScreenState();
}

class _CertificateViewScreenState extends State<CertificateViewScreen> {
  final CertificateService _certificateService = CertificateService();
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    try {
      await _certificateService.downloadOrPrintPdf(widget.certificate);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open PDF viewer: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleShareWhatsApp() async {
    try {
      await _certificateService.shareOnWhatsApp(widget.certificate);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open WhatsApp: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cert = widget.certificate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Donation Certificate',
          style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: 'Share on WhatsApp',
            onPressed: _handleShareWhatsApp,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            tooltip: 'Download PDF',
            onPressed: _handleDownload,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            // Action Buttons Bar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _handleDownload,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    label: const Text('Download / Print PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _handleShareWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.gutter * 1.5),

            // Visual Certificate Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: const Color(0xFF6750A4), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFFE0B654), width: 1.5),
                ),
                child: Column(
                  children: [
                    // Foundation Header & Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/Ngo_Logo.png',
                            height: 44,
                            width: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.volunteer_activism_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cert.foundationName.toUpperCase(),
                              style: AppTextStyles.headlineMd.copyWith(
                                color: const Color(0xFF6750A4),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '${cert.foundationTagline} · Regd. Public Charitable Trust',
                              style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Certificate Ribbon Title
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE0B654), width: 1.5),
                          bottom: BorderSide(color: Color(0xFFE0B654), width: 1.5),
                        ),
                      ),
                      child: Text(
                        'CERTIFICATE OF APPRECIATION',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelCaps.copyWith(
                          fontSize: 13,
                          letterSpacing: 2,
                          color: const Color(0xFF1C1B1F),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'This certificate is gratefully presented to',
                      style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),

                    const SizedBox(height: 8),

                    // Donor Name
                    Text(
                      cert.donorName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: const Color(0xFF6750A4),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),

                    Container(
                      width: 180,
                      height: 1.5,
                      color: const Color(0xFF6750A4),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                    ),

                    const SizedBox(height: 6),

                    // Appreciation text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.bodyMd.copyWith(
                            color: const Color(0xFF333333),
                            height: 1.6,
                            fontSize: 13,
                          ),
                          children: [
                            const TextSpan(text: 'In heartfelt appreciation of your generous contribution of '),
                            TextSpan(
                              text: '₹${cert.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6750A4)),
                            ),
                            const TextSpan(text: ' towards "'),
                            TextSpan(
                              text: cert.causeTitle,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text: '" through the Birthday for a Cause initiative on ${_formatDate(cert.issuedAt)}.\nYour benevolence helps bring education, meals, and real hope to children in need.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Verification Seal & Signatures
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Verification info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID: ${cert.id}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
                              ),
                            ),
                            Text(
                              'Ref: ${cert.razorpayPaymentId}',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Date: ${_formatDate(cert.issuedAt)}',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        // Center: Golden Verified Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0B654)),
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(0xFFFFF9E6),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.verified_rounded, color: Color(0xFF6750A4), size: 20),
                              SizedBox(height: 2),
                              Text(
                                'VERIFIED GIFT',
                                style: TextStyle(
                                  color: Color(0xFF6750A4),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: Signatory
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(width: 110, height: 1, color: Colors.grey.shade400),
                            const SizedBox(height: 4),
                            Text(
                              cert.signatoryName,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              cert.signatoryTitle,
                              style: TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Statutory Disclaimer
                    Text(
                      '*Note: This is an official token of appreciation for your charitable contribution and does not constitute a tax deduction receipt under Section 80G.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 8.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sectionGap),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
