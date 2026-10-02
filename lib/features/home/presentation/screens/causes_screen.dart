import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/shared/widgets/appbar_screen.dart';
import 'package:paranubhutifoundation/shared/widgets/bottam_navigation_screen.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/features/donation/presentation/screen/donate_screen.dart';

/// Causes screen — "Meaningful Gifts". A vertical list of large cause cards
/// (image + tag + title + description + Donate button), followed by an
/// overall "Together, we grow" progress summary.
class CausesScreen extends StatelessWidget {
  const CausesScreen({super.key});

  // TODO: replace with causes fetched from Firestore via a provider.

  static const List<_CauseDetail> _causes = [
    _CauseDetail(
      id: 'health',
      tag: 'HEALTHCARE',
      tagColor: AppColors.tertiaryContainer,
      onTagColor: AppColors.onTertiaryContainer,
      imagePath: 'assets/images/health_checkup.jpg',
      title: 'Health Support',
      description:
      'Bringing timely care to those who need it most through medicine assistance, general health check-ups, and diagnostic tests, because early diagnosis saves precious lives.',
    ),
    _CauseDetail(
      id: 'education',
      tag: 'KNOWLEDGE',
      tagColor: AppColors.secondaryContainer,
      onTagColor: AppColors.onSecondaryContainer,
      imagePath: 'assets/images/education_support.jpg',
      title: 'Education Support',
      description:
      'Opening doors for the next generation through scholarships, school supplies, and literacy programs that empower children from underserved communities to dream bigger.',
    ),
    _CauseDetail(
      id: 'women',
      tag: 'EMPOWERMENT',
      tagColor: AppColors.primaryContainer,
      onTagColor: AppColors.onPrimaryContainer,
      imagePath: 'assets/images/women_empowerment.jpg',
      title: 'Women Empowerment',
      description:
      'Strengthening families by investing in women through hygiene and health kits, skill development programs, and livelihood support that builds lasting independence.',
    ),
    _CauseDetail(
      id: 'environment',
      tag: 'PLANET',
      tagColor: AppColors.tertiary,
      onTagColor: AppColors.onTertiary,
      imagePath: 'assets/images/tree_plantation.jpeg',
      title: 'Environment',
      description:
      'Protecting our shared home through reforestation projects, ocean cleanup initiatives, and climate education that ensures a green birthday for future generations.',
    ),
  ];

  static const double _totalRaised = 42000;
  static const double _totalGoal = 50000;

  void _goToDonate(BuildContext context, String causeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DonateScreen(preselectedCauseId: causeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalRaised / _totalGoal).clamp(0, 1).toDouble();
    final percentAchieved = (progress * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:const AppBarScreen(),
      bottomNavigationBar: const BottomNavigationScreen(selectedIndex: 1),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.unit * 2,
          ),
          children: [
            Text('Meaningful Gifts', style: AppTextStyles.displayLgMobile.copyWith(fontSize: 26, color: AppColors.primary)),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'This year, turn your celebration into lasting impact. Choose a cause that resonates with your heart and invite your friends to give a gift that truly matters.',
              style: AppTextStyles.bodyMd,
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            ..._causes.map(
                  (cause) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap - AppSpacing.unit),
                child: _CauseCard(
                  cause: cause,
                  onDonate: () => _goToDonate(context, cause.id),
                ),
              ),
            ),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sectionGap - AppSpacing.unit),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Together, we grow.',
                      style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.unit),
                    Text(
                      'Over ₹${_totalRaised.toStringAsFixed(0)} raised this month for these causes.',
                      style: AppTextStyles.bodyMd,
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.unit),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Goal: ₹${_totalGoal.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyMd.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant),
                        ),
                        Text(
                          '$percentAchieved% Achieved',
                          style: AppTextStyles.bodyMd.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
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
}

class _CauseDetail {
  final String id;
  final String tag;
  final Color tagColor;
  final Color onTagColor;
  final String imagePath;
  final String title;
  final String description;

  const _CauseDetail({
    required this.id,
    required this.tag,
    required this.tagColor,
    required this.onTagColor,
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

/// Large cause card: image with a colored tag badge, title, description,
/// and a "Donate to this cause" button.
class _CauseCard extends StatelessWidget {
  final _CauseDetail cause;
  final VoidCallback onDonate;

  const _CauseCard({required this.cause, required this.onDonate});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.asset(
                cause.imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 180,
                  color: AppColors.surfaceContainerHigh,
                  child: Icon(Icons.image_rounded, color: AppColors.onSurfaceVariant, size: 40),
                ),
              ),
              Positioned(
                top: AppSpacing.unit,
                left: AppSpacing.unit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cause.tagColor,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    cause.tag,
                    style: AppTextStyles.labelCaps.copyWith(color: cause.onTagColor),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cause.title, style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontSize: 20)),
                const SizedBox(height: AppSpacing.unit),
                Text(cause.description, style: AppTextStyles.bodyMd),
                const SizedBox(height: AppSpacing.gutter),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDonate,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.card_giftcard_rounded, size: 18),
                        SizedBox(width: AppSpacing.unit),
                        Text('Donate to this cause'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}