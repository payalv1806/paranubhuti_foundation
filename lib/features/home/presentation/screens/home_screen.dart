import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paranubhutifoundation/shared/widgets/bottam_navigation_screen.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/config/routes/routes_name.dart';

// 👇 adjust these paths to wherever these screens actually live in your project
import 'package:paranubhutifoundation/features/home/presentation/screens/register_birthday_screen.dart';
import 'package:paranubhutifoundation/features/donation/presentation/screen/donate_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/notification_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/create_fundraiser_screen.dart';

/// Home screen — matches the "Birthday Cause" Stitch design:
/// header → headline → Your Birthday card → Someone Special card →
/// Quick Actions (Donate Now / Share a Fundraiser) → Featured Cause.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            Text(
              'CELEBRATE WITH PURPOSE',
              style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text('Make your day mean more.', style: AppTextStyles.displayLgMobile),

            const SizedBox(height: AppSpacing.gutter * 1.2),

            // Daily Social Proof Message
            const _DailySocialProofBanner(),

            const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),

            _ActionCard(
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
            ),
            const SizedBox(height: AppSpacing.gutter),

            _ActionCard(
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
            ),

            const SizedBox(height: AppSpacing.sectionGap),

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

            const SizedBox(height: AppSpacing.sectionGap),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Featured Cause', style: AppTextStyles.headlineMd),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, RoutesNames.causes);

                  },
                  child: Text(
                    'See All',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),

            const _FeaturedCauseCard(
              tag: 'Education',
              imagePath: 'assets/images/education.jpg',
              title: 'Birthday Books for All',
              description:
              'Help us provide 1,000 books to children in underserved communities this month.',
              amountRaised: 4200,
              goalAmount: 5000,
            ),

            const SizedBox(height: AppSpacing.sectionGap),
          ],
        ),
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
            'Birthday Cause',
            style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontSize: 20),
          ),
        ],
      ),
      actions: [
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$dueCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
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

/// White card used for "Your birthday" / "Someone special?" — icon, title,
/// description, and a CTA button slot.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Widget button;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sectionGap - AppSpacing.unit),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: AppSpacing.gutter),
            Text(title, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.unit),
            Text(description, style: AppTextStyles.bodyMd),
            const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),
            SizedBox(width: double.infinity, child: button),
          ],
        ),
      ),
    );
  }
}

/// Solid coral pill button, e.g. "Add your birthday →"
class _FilledPillButton extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final VoidCallback onPressed;

  const _FilledPillButton({required this.label, required this.onPressed, this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
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

/// Colored tappable tile used for Quick Actions ("Donate Now", "Share a
/// Fundraiser") — background color passed in (secondaryContainer / primaryContainer).
class _QuickActionTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.gutter + AppSpacing.unit),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.unit),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.onSurface, size: 22),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineMd.copyWith(fontSize: 18, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface.withValues(alpha: 0.75)),
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

/// Featured cause card — image with a category tag, title, description,
/// and a "$X raised / Goal: $Y" progress bar.
class _FeaturedCauseCard extends StatelessWidget {
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

  double get _progress => goalAmount <= 0 ? 0 : (amountRaised / goalAmount).clamp(0, 1);

  String _formatAmount(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

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
                imagePath,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 160,
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
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    tag,
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
                Text(title, style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                const SizedBox(height: AppSpacing.unit),
                Text(description, style: AppTextStyles.bodyMd),
                const SizedBox(height: AppSpacing.gutter),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${_formatAmount(amountRaised)} raised',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 13,
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
                const SizedBox(height: AppSpacing.unit),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
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

/// Dynamic "Birthday for a Cause" social-proof message banner.
/// Displays a daily random number between 1,500 and 2,000 that stays consistent
/// throughout the entire day and automatically refreshes on the next day.
class _DailySocialProofBanner extends StatefulWidget {
  const _DailySocialProofBanner();

  @override
  State<_DailySocialProofBanner> createState() => _DailySocialProofBannerState();
}

class _DailySocialProofBannerState extends State<_DailySocialProofBanner> {
  int? _dailyCount;
  int _templateIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyCount();
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
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
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
  }
}