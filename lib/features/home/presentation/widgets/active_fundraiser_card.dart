import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/features/home/presentation/widgets/fundraiser_poster_widget.dart';

class ActiveFundraiserCard extends StatelessWidget {
  final String fundraiserId;
  final Map<String, dynamic> data;

  const ActiveFundraiserCard({
    super.key,
    required this.fundraiserId,
    required this.data,
  });

  String _formatAmount(num value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  String _resolveImagePath() {
    final customImage = data['imageUrl'] ?? data['imagePath'] ?? data['coverImage'];
    if (customImage != null && customImage is String && customImage.isNotEmpty) {
      return customImage;
    }

    final causeId = (data['causeId'] ?? '').toString().toLowerCase();
    final causeTitle = (data['causeTitle'] ?? '').toString().toLowerCase();

    if (causeId.contains('health') || causeTitle.contains('health')) {
      return 'assets/images/health_checkup.jpg';
    } else if (causeId.contains('women') || causeTitle.contains('women')) {
      return 'assets/images/women_empowerment.jpg';
    } else if (causeId.contains('env') ||
        causeTitle.contains('tree') ||
        causeTitle.contains('environment')) {
      return 'assets/images/tree_plantation.jpeg';
    } else {
      return 'assets/images/education_support.jpg';
    }
  }

  String _resolvePaymentUrl() {
    final existing = data['razorpayPaymentLink'];
    if (existing != null && existing is String && existing.startsWith('http')) {
      return existing;
    }
    final title = data['title'] ?? 'Birthday Fundraiser';
    return 'https://pages.razorpay.com/pl_TubwVN0NmxjOSy/view?fundraiser_id=$fundraiserId&title=${Uri.encodeComponent(title.toString())}';
  }

  Future<void> _openPaymentLink(BuildContext context) async {
    final url = _resolvePaymentUrl();
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open donation page: $url')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening donation page: $e')),
        );
      }
    }
  }

  void _shareFundraiser(BuildContext context) {
    showFundraiserPosterModal(
      context: context,
      fundraiserId: fundraiserId,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Birthday Fundraiser';
    final causeTitle = data['causeTitle'] ?? 'Education';
    final story = (data['story'] ?? data['message'] ?? '').toString().trim();
    final totalRaised = (data['totalRaised'] as num?)?.toDouble() ?? 0.0;
    final goalAmount = (data['goalAmount'] as num?)?.toDouble() ?? 1000.0;
    final donorCount = (data['donorCount'] as num?)?.toInt() ?? 0;
    final isGoalReached = data['isGoalReached'] == true || (goalAmount > 0 && totalRaised >= goalAmount);

    final progress = goalAmount <= 0 ? 0.0 : (totalRaised / goalAmount).clamp(0.0, 1.0);
    final imagePath = _resolveImagePath();
    final isNetworkImage = imagePath.startsWith('http');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Banner with Tag Overlay (matching Featured Cause design)
          Stack(
            children: [
              SizedBox(
                height: 165,
                width: double.infinity,
                child: isNetworkImage
                    ? Image.network(
                        imagePath,
                        height: 165,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/education_support.jpg',
                          height: 165,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        imagePath,
                        height: 165,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/education.jpg',
                          height: 165,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),
              ),
              // Cause Tag Badge
              Positioned(
                top: AppSpacing.unit * 1.5,
                left: AppSpacing.unit * 1.5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B), // Teal badge
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    causeTitle.toString().toUpperCase(),
                    style: AppTextStyles.labelCaps.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              if (isGoalReached)
                Positioned(
                  top: AppSpacing.unit * 1.5,
                  right: AppSpacing.unit * 1.5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Goal Reached! 🎉',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Content section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toString(),
                  style: AppTextStyles.headlineMd.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (story.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    story,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.gutter),

                // Raised & Goal Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${_formatAmount(totalRaised)} raised',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Goal: ₹${_formatAmount(goalAmount)}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isGoalReached ? Colors.green : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '$donorCount ${donorCount == 1 ? "supporter" : "supporters"}',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gutter),

                // Actions: Donate Now and Share
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => _openPaymentLink(context),
                        icon: const Icon(Icons.favorite_rounded, size: 18),
                        label: const Text('Donate Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _shareFundraiser(context),
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
        ],
      ),
    );
  }
}
