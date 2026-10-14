import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paranubhutifoundation/shared/widgets/appbar_screen.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_text_styles.dart';
import '/core/theme/app_theme.dart';
import '/services/auth_service.dart';
import 'package:paranubhutifoundation/shared/widgets/bottam_navigation_screen.dart';
import 'register_birthday_screen.dart';
import 'edit_profile_screen.dart';
import 'package:paranubhutifoundation/authentication/login_screen.dart';
import 'package:paranubhutifoundation/services/admin_service.dart';
import 'package:paranubhutifoundation/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:paranubhutifoundation/services/certificate_service.dart';
import 'package:paranubhutifoundation/features/donation/presentation/screen/my_certificates_screen.dart';
import 'package:paranubhutifoundation/features/donation/presentation/screen/certificate_view_screen.dart';

/// Profile screen — user info, stats (total raised / causes led), their
/// registered birthdays, recent donations, and account settings.
///
/// Reads live from Firestore: `users/{uid}`, `birthdays` where
/// ownerId == uid, and `donations` where userId == uid.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _pushNotificationsEnabled = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _openEditProfile(String currentName, String? currentPhone, String? currentAvatarIcon) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          currentName: currentName,
          currentPhone: currentPhone,
          currentAvatarIcon: currentAvatarIcon,
        ),
      ),
    );
  }

  Future<void> _openBirthdaySettings(String docId, String personName, int currentReminderDays) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(personName, style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                const SizedBox(height: AppSpacing.gutter),

                Text('REMIND ME BEFORE', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
                const SizedBox(height: AppSpacing.unit),
                Wrap(
                  spacing: AppSpacing.unit,
                  children: [1, 3, 7].map((days) {
                    final isSelected = days == currentReminderDays;
                    return ChoiceChip(
                      label: Text('$days day${days > 1 ? 's' : ''}'),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      onSelected: (_) async {
                        await FirebaseFirestore.instance.collection('birthdays').doc(docId).update({
                          'reminderDaysBefore': days,
                        });
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    label: Text('Delete this birthday', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error)),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('birthdays').doc(docId).delete();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.gutter),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBarScreen(),
      bottomNavigationBar: const BottomNavigationScreen(selectedIndex: 2),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, userSnapshot) {
              final userData = userSnapshot.data?.data();
              final name = userData?['name'] as String? ?? 'Your Name';
              final phone = userData?['phone'] as String? ?? FirebaseAuth.instance.currentUser?.phoneNumber;
              final avatarIcon = userData?['avatarIcon'] as String? ?? 'person';

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                  vertical: AppSpacing.unit * 2,
                ),
                children: [
                  _ProfileHeader(
                    name: name,
                    phone: phone,
                    avatarIcon: avatarIcon,
                    onEditTap: () => _openEditProfile(name, phone, avatarIcon),
                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('donations')
                        .where('userId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, donationSnapshot) {
                      final docs = donationSnapshot.data?.docs ?? [];
                      final totalRaised = docs.fold<double>(
                        0,
                        (total, doc) => total + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
                      );
                      final causesLed = docs.map((d) => d.data()['causeId']).toSet().length;

                      return Row(
                        children: [
                          Expanded(
                            child: _AnimatedStatCard(
                              value: '₹${totalRaised.toStringAsFixed(0)}',
                              label: 'Total Raised',
                              valueColor: AppColors.primary,
                              icon: Icons.volunteer_activism_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.gutter),
                          Expanded(
                            child: _AnimatedStatCard(
                              value: '$causesLed',
                              label: 'Causes Led',
                              valueColor: AppColors.tertiary,
                              icon: Icons.favorite_rounded,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Registered\nBirthdays', style: AppTextStyles.headlineMd.copyWith(fontSize: 22)),
                      _AnimatedAddButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterBirthdayScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gutter),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('birthdays')
                        .where('ownerId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.gutter),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.gutter),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.cake_outlined, size: 40, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                              const SizedBox(height: AppSpacing.unit),
                              Text('No birthdays registered yet.', style: AppTextStyles.bodyMd),
                              const SizedBox(height: AppSpacing.unit),
                              Text(
                                'Add your birthday to get started!',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          final dob = (data['dob'] as Timestamp?)?.toDate();
                          final reminderDays = (data['reminderDaysBefore'] as num?)?.toInt() ?? 3;
                          final personName = data['personName'] as String? ?? '—';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
                            child: _BirthdayTile(
                              name: personName,
                              dateLabel: dob != null ? _formatDate(dob) : '—',
                              status: data['relation'] == 'self' ? 'Active' : 'Scheduled',
                              onSettingsTap: () => _openBirthdaySettings(doc.id, personName, reminderDays),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Recent Donations', style: AppTextStyles.headlineMd.copyWith(fontSize: 22)),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyCertificatesScreen()),
                          );
                        },
                        icon: const Icon(Icons.card_membership_rounded, size: 16, color: AppColors.primary),
                        label: Text(
                          'My Certificates',
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gutter),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.unit),
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('donations')
                            .where('userId', isEqualTo: uid)
                            .orderBy('createdAt', descending: true)
                            .limit(3)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.gutter),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(AppSpacing.gutter),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                                  const SizedBox(height: AppSpacing.unit),
                                  Text('No donations yet.', style: AppTextStyles.bodyMd),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: [
                              ...docs.map((doc) {
                                final data = doc.data();
                                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                                final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                                final paymentStatus = data['paymentStatus'] as String? ?? 'completed';
                                return _DonationRow(
                                  donationId: doc.id,
                                  paymentStatus: paymentStatus,
                                  title: data['causeId'] as String? ?? 'Donation',
                                  dateLabel: createdAt != null ? _formatDate(createdAt) : '—',
                                  amount: amount,
                                );
                              }),
                              TextButton(
                                onPressed: () {
                                  // TODO: navigate to a full donation history screen
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'VIEW ALL HISTORY',
                                      style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  Text('Account Settings', style: AppTextStyles.headlineMd.copyWith(fontSize: 22)),
                  const SizedBox(height: AppSpacing.gutter),

                  Card(
                    child: Column(
                      children: [
                        if (AdminService.isAdmin) ...[
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                            ),
                            title: Text(
                              'Admin Dashboard',
                              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                            subtitle: Text(
                              'Manage notification emails & announcements',
                              style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                              );
                            },
                          ),
                          const Divider(height: 1),
                        ],
                        SwitchListTile(
                          secondary: Icon(Icons.notifications_none_rounded, color: AppColors.onSurface),
                          title: Text('Push Notifications', style: AppTextStyles.bodyMd),
                          value: _pushNotificationsEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (value) => setState(() => _pushNotificationsEnabled = value),
                        ),
                        const Divider(height: 1),
                        _SettingsListTile(
                          icon: Icons.card_membership_rounded,
                          title: 'My Donation Certificates',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyCertificatesScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsListTile(
                          icon: Icons.shield_outlined,
                          title: 'Privacy & Security',
                          onTap: () {
                            // TODO: navigate to a Privacy & Security screen
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                          ),
                          title: Text('Logout', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                          onTap: () async {
                            await _authService.signOut();
                            if (!context.mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sectionGap),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Profile header with gradient ring around the avatar.
class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? phone;
  final String avatarIcon;
  final VoidCallback onEditTap;

  const _ProfileHeader({
    required this.name,
    this.phone,
    required this.avatarIcon,
    required this.onEditTap,
  });

  static IconData _iconFor(String id) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.surfaceContainerLowest,
                  child: Icon(_iconFor(avatarIcon), size: 46, color: AppColors.primary),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        Text(name, style: AppTextStyles.headlineMd),
        if (phone != null && phone!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_android_rounded, size: 15, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                phone!,
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: Colors.green.shade300, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 10, color: Colors.green.shade700),
                    const SizedBox(width: 2),
                    Text(
                      'Verified',
                      style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '✨ BIRTHDAY AMBASSADOR',
            style: AppTextStyles.labelCaps.copyWith(
              color: Colors.white,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Stat card with hover effect and icon.
class _AnimatedStatCard extends StatefulWidget {
  final String value;
  final String label;
  final Color valueColor;
  final IconData icon;

  const _AnimatedStatCard({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.icon,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.diagonal3Values(_hovering ? 1.03 : 1.0, _hovering ? 1.03 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: _hovering ? widget.valueColor.withValues(alpha: 0.3) : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovering
                  ? widget.valueColor.withValues(alpha: 0.15)
                  : AppColors.cardShadow,
              blurRadius: _hovering ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.valueColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.valueColor, size: 20),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                widget.value,
                style: AppTextStyles.headlineMd.copyWith(color: widget.valueColor, fontSize: 22),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add birthday button with hover effect.
class _AnimatedAddButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedAddButton({required this.onPressed});

  @override
  State<_AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<_AnimatedAddButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: _hovering ? AppColors.primaryGradient : null,
          color: _hovering ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: _hovering ? null : Border.all(color: AppColors.primary),
        ),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: _hovering ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Add New',
                style: AppTextStyles.bodyMd.copyWith(
                  color: _hovering ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings list tile with hover effect.
class _SettingsListTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsListTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<_SettingsListTile> createState() => _SettingsListTileState();
}

class _SettingsListTileState extends State<_SettingsListTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovering ? AppColors.surfaceContainerLow.withValues(alpha: 0.5) : Colors.transparent,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(widget.icon, color: AppColors.onSurface, size: 20),
          ),
          title: Text(widget.title, style: AppTextStyles.bodyMd),
          trailing: Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _BirthdayTile extends StatefulWidget {
  final String name;
  final String dateLabel;
  final String status;
  final VoidCallback onSettingsTap;

  const _BirthdayTile({
    required this.name,
    required this.dateLabel,
    required this.status,
    required this.onSettingsTap,
  });

  @override
  State<_BirthdayTile> createState() => _BirthdayTileState();
}

class _BirthdayTileState extends State<_BirthdayTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.diagonal3Values(_hovering ? 1.02 : 1.0, _hovering ? 1.02 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: _hovering ? AppColors.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovering ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardShadow,
              blurRadius: _hovering ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryContainer.withValues(alpha: 0.3),
                  AppColors.primaryContainer.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(Icons.cake_rounded, color: AppColors.primary),
          ),
          title: Text(widget.name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              Text(widget.dateLabel, style: AppTextStyles.bodyMd.copyWith(fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.status == 'Active'
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  widget.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.status == 'Active' ? Colors.green.shade700 : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant),
            onPressed: widget.onSettingsTap,
          ),
        ),
      ),
    );
  }
}

class _DonationRow extends StatelessWidget {
  final String? donationId;
  final String paymentStatus;
  final String title;
  final String dateLabel;
  final double amount;

  const _DonationRow({
    this.donationId,
    this.paymentStatus = 'completed',
    required this.title,
    required this.dateLabel,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.unit),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(dateLabel, style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (donationId != null && paymentStatus == 'completed') ...[
                InkWell(
                  onTap: () async {
                    try {
                      final cert = await CertificateService().generateOrGetCertificate(donationId!);
                      if (context.mounted && cert != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CertificateViewScreen(certificate: cert),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not load certificate: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.card_membership_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Certificate',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '+₹${amount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMd.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}