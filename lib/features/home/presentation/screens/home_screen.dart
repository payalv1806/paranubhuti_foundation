import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paranubhutifoundation/shared/widgets/bottam_navigation_screen.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';


// 👇 adjust these paths to wherever these screens actually live in your project
import 'package:paranubhutifoundation/features/home/presentation/screens/register_birthday_screen.dart';
import 'package:paranubhutifoundation/features/donation/presentation/screen/donate_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/notification_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/create_fundraiser_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/widgets/active_fundraiser_card.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/all_fundraisers_screen.dart';
import 'package:paranubhutifoundation/services/admin_service.dart';
import 'package:paranubhutifoundation/features/admin/presentation/screens/admin_dashboard_screen.dart';

/// Home screen — matches the "Birthday for cause" Stitch design:
/// header → headline → Your Birthday card → Someone Special card →
/// Quick Actions (Donate Now / Share a Fundraiser) → Featured Cause.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Create staggered animations for 6 elements
    _fadeAnimations = List.generate(6, (i) {
      final start = i * 0.12;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(6, (i) {
      final start = i * 0.12;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Widget _staggerChild(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index.clamp(0, 5)],
      child: SlideTransition(
        position: _slideAnimations[index.clamp(0, 5)],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const _HomeAppBar(),
      bottomNavigationBar: const BottomNavigationScreen(selectedIndex: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.unit * 2,
          ),
          children: [
            // Hero section with gradient
            _staggerChild(0, _buildHeroSection()),

            if (AdminService.isAdmin) ...[
              const SizedBox(height: AppSpacing.gutter),
              const _AdminQuickBanner(),
            ],

            const SizedBox(height: AppSpacing.gutter * 1.2),

            // Daily Social Proof Message
            _staggerChild(1, const _DailySocialProofBanner()),

            const SizedBox(height: AppSpacing.gutter),

            // Latest Community Announcement Banner
            const _LatestAnnouncementBanner(),

            const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),

            _staggerChild(2, _AnimatedActionCard(
              icon: Icons.cake_rounded,
              iconColor: AppColors.primary,
              title: 'Your birthday',
              description: "Let's turn your special day into a world-changing gift.",
              button: _FilledPillButton(
                label: 'Add your birthday',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterBirthdayScreen()),
                  );
                },
              ),
            )),
            const SizedBox(height: AppSpacing.gutter),

            _staggerChild(3, _AnimatedActionCard(
              icon: Icons.groups_rounded,
              iconColor: AppColors.tertiary,
              title: 'Someone special?',
              description: 'Honor a loved one by starting a fundraiser for their birthday.',
              button: _OutlinedPillButton(
                label: "Add someone else's",
                trailingIcon: Icons.add_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterBirthdayScreen.someoneElse()),
                  );
                },
              ),
            )),

            const SizedBox(height: AppSpacing.sectionGap),

            _staggerChild(4, Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Actions', style: AppTextStyles.headlineMd),
                const SizedBox(height: AppSpacing.gutter),

                _QuickActionTile(
                  backgroundColor: AppColors.secondaryContainer,
                  icon: Icons.volunteer_activism_rounded,
                  title: 'Donate Now',
                  description: 'Support a trending cause immediately.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DonateScreen()),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.gutter),
                _QuickActionTile(
                  backgroundColor: AppColors.primaryContainer,
                  icon: Icons.ios_share_rounded,
                  title: 'Share a Fundraiser',
                  description: 'Invite friends to join a celebration of giving.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateFundraiserScreen()),
                    );
                  },
                ),
              ],
            )),

            const SizedBox(height: AppSpacing.sectionGap),

            _staggerChild(5, const _ActiveFundraisersSection()),

            const SizedBox(height: AppSpacing.sectionGap),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '✨ CELEBRATE WITH PURPOSE',
              style: AppTextStyles.labelCaps.copyWith(
                color: Colors.white,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            'Make your day\nmean more.',
            style: AppTextStyles.displayLgMobile.copyWith(
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

/// App bar with a bell icon that navigates to NotificationsScreen and shows
/// a live badge counting birthdays currently inside their reminder window
/// (dob's reminderDaysBefore).
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/Ngo_Logo.png',
              height: 28,
              width: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text('🎉 ', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Birthday for cause',
            style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontSize: 20),
          ),
        ],
      ),
      actions: [
        if (AdminService.isAdmin)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
            tooltip: 'Admin Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              );
            },
          ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: uid == null
              ? null
              : FirebaseFirestore.instance
              .collection('birthdays')
              .where('ownerId', isEqualTo: uid)
              .snapshots(),
          builder: (context, snapshot) {
            final dueCount = _countDue(snapshot.data?.docs);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none_rounded, color: AppColors.onSurface),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                if (dueCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _PulsingBadge(count: dueCount),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  static int _countDue(List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs) {
    if (docs == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var count = 0;
    for (final doc in docs) {
      final data = doc.data();
      final dobTs = data['dob'] as Timestamp?;
      if (dobTs == null) continue;
      final reminderDaysBefore = (data['reminderDaysBefore'] as num?)?.toInt() ?? 0;
      if (reminderDaysBefore <= 0) continue;

      final dob = dobTs.toDate();
      var next = DateTime(today.year, dob.month, dob.day);
      if (next.isBefore(today)) {
        next = DateTime(today.year + 1, dob.month, dob.day);
      }
      final daysUntil = next.difference(today).inDays;
      if (daysUntil <= reminderDaysBefore) count++;
    }
    return count;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Pulsing notification badge — draws attention with a gentle scale animation.
class _PulsingBadge extends StatefulWidget {
  final int count;
  const _PulsingBadge({required this.count});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.4 * _controller.value),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              '${widget.count}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}

/// White card with hover / tap scale effect — used for "Your birthday" / "Someone special?"
class _AnimatedActionCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Widget button;

  const _AnimatedActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.button,
  });

  @override
  State<_AnimatedActionCard> createState() => _AnimatedActionCardState();
}

class _AnimatedActionCardState extends State<_AnimatedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _hovering = hovering);
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          final scale = 1.0 + (_hoverController.value * 0.02);
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(
                  color: _hovering
                      ? widget.iconColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _hovering
                        ? widget.iconColor.withValues(alpha: 0.12)
                        : AppColors.cardShadow,
                    blurRadius: _hovering ? 20 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sectionGap - AppSpacing.unit),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated icon container with gradient background
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.iconColor.withValues(alpha: _hovering ? 0.2 : 0.1),
                            widget.iconColor.withValues(alpha: _hovering ? 0.08 : 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Icon(widget.icon, size: 28, color: widget.iconColor),
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    Text(widget.title, style: AppTextStyles.headlineMd),
                    const SizedBox(height: AppSpacing.unit),
                    Text(widget.description, style: AppTextStyles.bodyMd),
                    const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),
                    SizedBox(width: double.infinity, child: widget.button),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Solid coral pill button with hover glow, e.g. "Add your birthday →"
class _FilledPillButton extends StatefulWidget {
  final String label;
  final IconData? trailingIcon;
  final VoidCallback onPressed;

  const _FilledPillButton({required this.label, required this.onPressed, this.trailingIcon});

  @override
  State<_FilledPillButton> createState() => _FilledPillButtonState();
}

class _FilledPillButtonState extends State<_FilledPillButton> {
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
          style: ElevatedButton.styleFrom(
            backgroundColor: _hovering ? AppColors.primaryContainer : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(widget.label, overflow: TextOverflow.ellipsis),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.unit),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.only(left: _hovering ? 4.0 : 0.0),
                  child: Icon(widget.trailingIcon, size: 18),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Coral-outlined pill button, e.g. "Add someone else's +"
class _OutlinedPillButton extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final VoidCallback onPressed;

  const _OutlinedPillButton({required this.label, required this.onPressed, this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.unit),
            Icon(trailingIcon, size: 18),
          ],
        ],
      ),
    );
  }
}

/// Colored tappable tile with scale-on-tap animation — used for Quick Actions
class _QuickActionTile extends StatefulWidget {
  final Color backgroundColor;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.backgroundColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) {
        _tapController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.gutter + AppSpacing.unit),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.unit + 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: AppColors.onSurface, size: 22),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.headlineMd.copyWith(fontSize: 18, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.description,
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Featured cause card — image with a category tag, title, description,
/// and an animated "raised / Goal" progress bar.
class _FeaturedCauseCard extends StatefulWidget {
  final String tag;
  final String imagePath;
  final String title;
  final String description;
  final double amountRaised;
  final double goalAmount;

  const _FeaturedCauseCard({
    required this.tag,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.amountRaised,
    required this.goalAmount,
  });

  @override
  State<_FeaturedCauseCard> createState() => _FeaturedCauseCardState();
}

class _FeaturedCauseCardState extends State<_FeaturedCauseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _hovering = false;

  double get _progress => widget.goalAmount <= 0 ? 0 : (widget.amountRaised / widget.goalAmount).clamp(0, 1);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(begin: 0, end: _progress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    // Delay to let the stagger animation complete before showing the progress bar
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String _formatAmount(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

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
                  ? AppColors.primary.withValues(alpha: 0.15)
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
            // Image with parallax-like overlay
            Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: _hovering ? 175 : 160,
                  width: double.infinity,
                  child: Image.asset(
                    widget.imagePath,
                    height: _hovering ? 175 : 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 160,
                      color: AppColors.surfaceContainerHigh,
                      child: Icon(Icons.image_rounded, color: AppColors.onSurfaceVariant, size: 40),
                    ),
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
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
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.tag,
                      style: AppTextStyles.labelCaps.copyWith(color: AppColors.onTertiaryContainer),
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
                  Text(widget.title, style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                  const SizedBox(height: AppSpacing.unit),
                  Text(widget.description, style: AppTextStyles.bodyMd),
                  const SizedBox(height: AppSpacing.gutter),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${_formatAmount(widget.amountRaised)} raised',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Goal: ₹${_formatAmount(widget.goalAmount)}',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.unit),

                  // Animated progress bar
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: Stack(
                          children: [
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                height: 10,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dynamic "Birthday for cause" social-proof message banner.
/// Displays a daily random number between 1,500 and 2,000 that stays consistent
/// throughout the entire day and automatically refreshes on the next day.
class _DailySocialProofBanner extends StatefulWidget {
  const _DailySocialProofBanner();

  @override
  State<_DailySocialProofBanner> createState() => _DailySocialProofBannerState();
}

class _DailySocialProofBannerState extends State<_DailySocialProofBanner>
    with SingleTickerProviderStateMixin {
  int? _dailyCount;
  int _templateIndex = 0;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadDailyCount();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  String _getTodayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  int _computeDeterministicFallback(DateTime now) {
    // Seeded random as instant synchronous fallback so there is never a blank gap or flicker
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return 1500 + Random(seed).nextInt(501); // 1,500 to 2,000 inclusive
  }

  Future<void> _loadDailyCount() async {
    final todayKey = _getTodayKey();
    final now = DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString('daily_social_proof_date');
      final savedCount = prefs.getInt('daily_social_proof_count');
      final savedTemplate = prefs.getInt('daily_social_proof_template');

      if (savedDate == todayKey &&
          savedCount != null &&
          savedCount >= 1500 &&
          savedCount <= 2000) {
        if (mounted) {
          setState(() {
            _dailyCount = savedCount;
            _templateIndex = savedTemplate ?? 0;
          });
        }
      } else {
        // Generate a new random number between 1,500 and 2,000 for the new day
        final newCount = 1500 + Random().nextInt(501);
        final newTemplate = Random().nextInt(2);

        await prefs.setString('daily_social_proof_date', todayKey);
        await prefs.setInt('daily_social_proof_count', newCount);
        await prefs.setInt('daily_social_proof_template', newTemplate);

        if (mounted) {
          setState(() {
            _dailyCount = newCount;
            _templateIndex = newTemplate;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _dailyCount = _computeDeterministicFallback(now);
          _templateIndex = (now.day % 2);
        });
      }
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _dailyCount ?? _computeDeterministicFallback(DateTime.now());
    final formattedCount = _formatNumber(count);

    final emoji = _templateIndex == 0 ? '🎂' : '❤️';
    final actionText = _templateIndex == 0
        ? 'celebrating their birthdays by donating to a cause today.'
        : 'making their birthdays meaningful by supporting a cause today.';

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.unit * 1.5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pulsing emoji container
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.1),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                onEnd: () {}, // TweenAnimationBuilder runs once; the shimmer controller adds life
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryFixed.withValues(alpha: 0.9),
                        AppColors.primaryFixed.withValues(alpha: 0.4),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.unit * 1.5),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      height: 1.35,
                      fontSize: 13.5,
                    ),
                    children: [
                      TextSpan(
                        text: '$formattedCount ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'people are $actionText',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Admin Quick Banner — displayed exclusively for the authorized admin (info@paranubhutifoundation.org).
class _AdminQuickBanner extends StatelessWidget {
  const _AdminQuickBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.9),
            AppColors.secondaryContainer.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Admin Portal',
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Text(
                        'AUTHORIZED',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage notification emails & announcements',
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

/// Community Announcements Banner — displays the latest announcement for all users.
class _LatestAnnouncementBanner extends StatelessWidget {
  const _LatestAnnouncementBanner();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data();
        final title = data['title'] as String? ?? 'Foundation Update';
        final content = data['content'] as String? ?? '';
        final category = data['category'] as String? ?? 'General';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.campaign_rounded, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'COMMUNITY ANNOUNCEMENT',
                    style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary, fontSize: 11),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: AppTextStyles.labelCaps.copyWith(color: AppColors.secondary, fontSize: 9.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 12.5,
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  label: Text(
                    'View all updates',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Active Fundraiser Section — displays the featured birthday fundraiser
/// with image banner, real-time total raised, progress bars, Share, and Donate Now buttons,
/// and a 'See All' button that navigates to AllFundraisersScreen.
class _ActiveFundraisersSection extends StatelessWidget {
  const _ActiveFundraisersSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('fundraisers')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final Map<String, dynamic> fundraiserData;
        final String fundraiserId;

        if (docs.isNotEmpty) {
          final featuredDoc = docs.first;
          fundraiserId = featuredDoc.id;
          fundraiserData = featuredDoc.data();
        } else {
          fundraiserId = 'sample_fundraiser';
          fundraiserData = {
            'title': 'Birthday Books for All',
            'causeTitle': 'Education Support',
            'causeId': 'education',
            'story': 'Help us provide 1,000 books to children in underserved communities this month.',
            'totalRaised': 4200.0,
            'goalAmount': 5000.0,
            'donorCount': 18,
            'status': 'active',
          };
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Birthday Fundraiser',
                          style: AppTextStyles.headlineMd,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllFundraisersScreen()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),
            ActiveFundraiserCard(
              fundraiserId: fundraiserId,
              data: fundraiserData,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
        );
      },
    );
  }
}
