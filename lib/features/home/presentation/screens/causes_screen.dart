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
class CausesScreen extends StatefulWidget {
  const CausesScreen({super.key});

  @override
  State<CausesScreen> createState() => _CausesScreenState();
}

class _CausesScreenState extends State<CausesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  late ScrollController _scrollController;

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

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
      appBar: const AppBarScreen(),
      bottomNavigationBar: const BottomNavigationScreen(selectedIndex: 1),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.unit * 2,
          ),
          children: [
            // Hero section with gradient
            _buildHeaderSection(),

            const SizedBox(height: AppSpacing.sectionGap),

            ...List.generate(_causes.length, (index) {
              return _AnimatedCauseEntry(
                delay: Duration(milliseconds: 200 + (index * 150)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap - AppSpacing.unit),
                  child: _CauseCard(
                    cause: _causes[index],
                    onDonate: () => _goToDonate(context, _causes[index].id),
                  ),
                ),
              );
            }),

            // Summary card with animated progress
            _AnimatedCauseEntry(
              delay: Duration(milliseconds: 200 + (_causes.length * 150)),
              child: _SummaryCard(
                totalRaised: _totalRaised,
                totalGoal: _totalGoal,
                progress: progress,
                percentAchieved: percentAchieved,
              ),
            ),

            const SizedBox(height: AppSpacing.sectionGap),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  'Meaningful Gifts',
                  style: AppTextStyles.displayLgMobile.copyWith(
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                'This year, turn your celebration into lasting impact. Choose a cause that resonates with your heart and invite your friends to give a gift that truly matters.',
                style: AppTextStyles.bodyMd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animates a child in with a delay — fade + slide up.
class _AnimatedCauseEntry extends StatefulWidget {
  final Duration delay;
  final Widget child;

  const _AnimatedCauseEntry({required this.delay, required this.child});

  @override
  State<_AnimatedCauseEntry> createState() => _AnimatedCauseEntryState();
}

class _AnimatedCauseEntryState extends State<_AnimatedCauseEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
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

/// Large cause card with hover/tap effects — image with a colored tag badge,
/// title, description, and a "Donate to this cause" button.
class _CauseCard extends StatefulWidget {
  final _CauseDetail cause;
  final VoidCallback onDonate;

  const _CauseCard({required this.cause, required this.onDonate});

  @override
  State<_CauseCard> createState() => _CauseCardState();
}

class _CauseCardState extends State<_CauseCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.diagonal3Values(_hovering ? 1.015 : 1.0, _hovering ? 1.015 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: [
            BoxShadow(
              color: _hovering
                  ? widget.cause.tagColor.withValues(alpha: 0.25)
                  : AppColors.cardShadow,
              blurRadius: _hovering ? 24 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: _hovering ? 195 : 180,
                  width: double.infinity,
                  child: Image.asset(
                    widget.cause.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 180,
                      color: AppColors.surfaceContainerHigh,
                      child: Icon(Icons.image_rounded, color: AppColors.onSurfaceVariant, size: 40),
                    ),
                  ),
                ),
                // Gradient overlay for readability
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.unit,
                  left: AppSpacing.unit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.cause.tagColor,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.cause.tag,
                      style: AppTextStyles.labelCaps.copyWith(color: widget.cause.onTagColor),
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
                  Text(
                    widget.cause.title,
                    style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontSize: 20),
                  ),
                  const SizedBox(height: AppSpacing.unit),
                  Text(widget.cause.description, style: AppTextStyles.bodyMd),
                  const SizedBox(height: AppSpacing.gutter),
                  SizedBox(
                    width: double.infinity,
                    child: _AnimatedDonateButton(onPressed: widget.onDonate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Donate button with hover glow and icon animation.
class _AnimatedDonateButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedDonateButton({required this.onPressed});

  @override
  State<_AnimatedDonateButton> createState() => _AnimatedDonateButtonState();
}

class _AnimatedDonateButtonState extends State<_AnimatedDonateButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedRotation(
                turns: _hovering ? 0.05 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.card_giftcard_rounded, size: 18),
              ),
              const SizedBox(width: AppSpacing.unit),
              const Text('Donate to this cause'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary card with animated progress bar.
class _SummaryCard extends StatefulWidget {
  final double totalRaised;
  final double totalGoal;
  final double progress;
  final int percentAchieved;

  const _SummaryCard({
    required this.totalRaised,
    required this.totalGoal,
    required this.progress,
    required this.percentAchieved,
  });

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sectionGap - AppSpacing.unit),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.unit * 1.5),
                Text(
                  'Together, we grow.',
                  style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Over ₹${widget.totalRaised.toStringAsFixed(0)} raised this month for these causes.',
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: AppSpacing.gutter),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.unit),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goal: ₹${widget.totalGoal.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                Text(
                  '${widget.percentAchieved}% Achieved',
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}