import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/services/poster_generator_service.dart';

/// Modal dialog that renders a preview of the auto-generated Fundraiser poster
/// and lets the user 1-tap share (image + pre-filled caption + Razorpay link) or download it.
Future<void> showFundraiserPosterModal({
  required BuildContext context,
  required String fundraiserId,
  required Map<String, dynamic> data,
}) async {
  final GlobalKey boundaryKey = GlobalKey();

  final creatorName = (data['creatorName'] ?? 'Kind Supporter').toString();
  final title = (data['title'] ?? '$creatorName\'s Birthday Fundraiser').toString();
  final causeTitle = (data['causeTitle'] ?? 'Birthday for a Cause').toString();
  final causeId = (data['causeId'] ?? '').toString();
  final totalRaised = (data['totalRaised'] as num?)?.toDouble() ?? 0.0;
  final goalAmount = (data['goalAmount'] as num?)?.toDouble() ?? 1000.0;
  final customMessage = (data['story'] ?? data['message'] ?? '').toString();
  final photoUrl = data['photoUrl'] as String?;
  final avatarIcon = (data['avatarIcon'] ?? 'cake').toString();

  final existingLink = data['razorpayPaymentLink'];
  final paymentUrl = (existingLink != null && existingLink is String && existingLink.startsWith('http'))
      ? existingLink
      : 'https://pages.razorpay.com/pl_TubwVN0NmxjOSy/view?fundraiser_id=$fundraiserId&title=${Uri.encodeComponent(title)}';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (sheetContext) {
      bool isSharing = false;
      bool isDownloading = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.gutter,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share Campaign Poster',
                              style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Share on WhatsApp & Instagram + link in bio',
                              style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gutter),

                  // The Poster Widget wrapped in RepaintBoundary for HD capture
                  Center(
                    child: RepaintBoundary(
                      key: boundaryKey,
                      child: FundraiserPosterWidget(
                        creatorName: creatorName,
                        title: title,
                        causeTitle: causeTitle,
                        causeId: causeId,
                        totalRaised: totalRaised,
                        goalAmount: goalAmount,
                        paymentUrl: paymentUrl,
                        customMessage: customMessage,
                        photoUrl: photoUrl,
                        avatarIcon: avatarIcon,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.gutter * 1.2),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: isSharing
                              ? null
                              : () async {
                                  setState(() => isSharing = true);
                                  try {
                                    final pngBytes = await PosterGeneratorService.capturePng(boundaryKey);
                                    if (pngBytes != null) {
                                      final shareText = '🎂 Celebrate my birthday with purpose! Support "$title" for Paranubhuti Foundation.\n\nEvery contribution makes a real difference! Donate here:\n$paymentUrl';
                                      await PosterGeneratorService.sharePosterWithLink(
                                        pngBytes: pngBytes,
                                        filename: 'birthday_fundraiser_${fundraiserId.substring(0, 8)}',
                                        shareMessage: shareText,
                                        subject: 'Support $title',
                                      );
                                    } else {
                                      if (sheetContext.mounted) {
                                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                                          const SnackBar(content: Text('Could not generate poster image.')),
                                        );
                                      }
                                    }
                                  } finally {
                                    if (sheetContext.mounted) setState(() => isSharing = false);
                                  }
                                },
                          icon: isSharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.share_rounded, size: 18),
                          label: Text(isSharing ? 'Sharing...' : 'Share Poster', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: isDownloading
                              ? null
                              : () async {
                                  setState(() => isDownloading = true);
                                  try {
                                    final pngBytes = await PosterGeneratorService.capturePng(boundaryKey);
                                    if (pngBytes != null) {
                                      final path = await PosterGeneratorService.downloadPoster(
                                        pngBytes: pngBytes,
                                        filename: 'birthday_poster_${fundraiserId.substring(0, 8)}',
                                      );
                                      if (sheetContext.mounted) {
                                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                                          SnackBar(
                                            content: Text('Poster saved to device: $path'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  } finally {
                                    if (sheetContext.mounted) setState(() => isDownloading = false);
                                  }
                                },
                          icon: isDownloading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download_rounded, size: 18),
                          label: Text(isDownloading ? 'Saving...' : 'Download'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// The visual flyer / poster widget that renders the donor/birthday campaign flyer.
class FundraiserPosterWidget extends StatelessWidget {
  final String creatorName;
  final String title;
  final String causeTitle;
  final String causeId;
  final double totalRaised;
  final double goalAmount;
  final String paymentUrl;
  final String? customMessage;
  final String? photoUrl;
  final String avatarIcon;

  const FundraiserPosterWidget({
    super.key,
    required this.creatorName,
    required this.title,
    required this.causeTitle,
    required this.causeId,
    required this.totalRaised,
    required this.goalAmount,
    required this.paymentUrl,
    this.customMessage,
    this.photoUrl,
    this.avatarIcon = 'cake',
  });

  String _resolveCauseImage() {
    final cid = causeId.toLowerCase();
    final ctitle = causeTitle.toLowerCase();
    if (cid.contains('health') || ctitle.contains('health')) {
      return 'assets/images/health_checkup.jpg';
    } else if (cid.contains('women') || ctitle.contains('women')) {
      return 'assets/images/women_empowerment.jpg';
    } else if (cid.contains('env') || ctitle.contains('tree') || ctitle.contains('environment')) {
      return 'assets/images/tree_plantation.jpeg';
    }
    return 'assets/images/education_support.jpg';
  }

  IconData _iconForAvatar(String id) {
    switch (id) {
      case 'cake':
        return Icons.cake_rounded;
      case 'volunteer':
        return Icons.volunteer_activism_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'person':
      default:
        return Icons.person_rounded;
    }
  }

  Widget _buildAvatar() {
    // If a photoUrl exists (base64 data URI, network URL, or local file)
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      final url = photoUrl!.trim();
      Widget imageChild;

      if (url.startsWith('data:image')) {
        try {
          final b64 = url.split(',').last;
          final bytes = base64Decode(b64);
          imageChild = Image.memory(
            bytes,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildIconAvatar(),
          );
        } catch (_) {
          imageChild = _buildIconAvatar();
        }
      } else if (url.startsWith('http')) {
        imageChild = Image.network(
          url,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildIconAvatar(),
        );
      } else {
        imageChild = Image.file(
          File(url),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildIconAvatar(),
        );
      }

      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD49A38), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(child: imageChild),
      );
    }

    return _buildIconAvatar();
  }

  Widget _buildIconAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _iconForAvatar(avatarIcon),
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = goalAmount <= 0 ? 0.0 : (totalRaised / goalAmount).clamp(0.0, 1.0);

    return Container(
      width: 325,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF8),
            Color(0xFFFFF5EA),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8D7C3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4524).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Header: NGO Logo & Official Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/Ngo_Logo.png',
                      height: 30,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Color(0xFFBA441A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'PARANUBHUTI FOUNDATION',
                            style: TextStyle(
                              color: Color(0xFF4A2411),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Celebrate With Purpose • 80G',
                            style: TextStyle(
                              color: Color(0xFF7A5A48),
                              fontSize: 8.0,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 11),
                    SizedBox(width: 2),
                    Text(
                      'VERIFIED',
                      style: TextStyle(color: Color(0xFF2E7D32), fontSize: 8.0, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Avatar Badge
          _buildAvatar(),

          const SizedBox(height: 10),

          // Creator & Birthday Title
          Text(
            creatorName,
            style: const TextStyle(
              color: Color(0xFFBA441A),
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          const Text(
            'is dedicating their Birthday to a Cause! 🎂',
            style: TextStyle(
              color: Color(0xFF3E281C),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 14),

          // Cause Card with Progress
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECDCCF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        _resolveCauseImage(),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: const Color(0xFF00897B),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00897B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              causeTitle.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: const TextStyle(color: Color(0xFF2E1E12), fontSize: 13, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Raised & Goal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${totalRaised.toInt()} raised',
                      style: const TextStyle(
                        color: Color(0xFFBA441A),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Goal: ₹${goalAmount.toInt()}',
                      style: const TextStyle(
                        color: Color(0xFF7A6556),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF3E7DC),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBA441A)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Scannable QR Code Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECDCCF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: QrImageView(
                    data: paymentUrl,
                    version: QrVersions.auto,
                    size: 70,
                    padding: EdgeInsets.zero,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF2E1E12),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF2E1E12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 13, color: Color(0xFFBA441A)),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Scan to Donate',
                              style: TextStyle(
                                color: Color(0xFF2E1E12),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Supports GPay, PhonePe, Paytm, or any UPI / Card.',
                        style: TextStyle(
                          color: Color(0xFF6D5D53),
                          fontSize: 9.0,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Text(
                        '✓ 100% Tax-Exempt under 80G',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Footer
          const Text(
            'Instead of birthday gifts, let\'s share smiles together!',
            style: TextStyle(
              color: Color(0xFF7A6556),
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'www.paranubhutifoundation.org',
            style: TextStyle(
              color: Color(0xFFBA441A),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
