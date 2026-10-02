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

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _pushNotificationsEnabled = true;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

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
                          child: _StatCard(
                            value: '₹${totalRaised.toStringAsFixed(0)}',
                            label: 'Total Raised',
                            valueColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gutter),
                        Expanded(
                          child: _StatCard(
                            value: '$causesLed',
                            label: 'Causes Led',
                            valueColor: AppColors.tertiary,
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
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterBirthdayScreen()),
                        );
                      },
                      child: Text(
                        'Add\nNew',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
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
                      return Text('No birthdays registered yet.', style: AppTextStyles.bodyMd);
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

                Text('My Recent Donations', style: AppTextStyles.headlineMd.copyWith(fontSize: 22)),
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
                            child: Text('No donations yet.', style: AppTextStyles.bodyMd),
                          );
                        }
                        return Column(
                          children: [
                            ...docs.map((doc) {
                              final data = doc.data();
                              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                              final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                              return _DonationRow(
                                title: data['causeId'] as String? ?? 'Donation',
                                dateLabel: createdAt != null ? _formatDate(createdAt) : '—',
                                amount: amount,
                              );
                            }),
                            TextButton(
                              onPressed: () {
                                // TODO: navigate to a full donation history screen
                              },
                              child: Text(
                                'VIEW ALL HISTORY',
                                style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary),
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
                      SwitchListTile(
                        secondary: Icon(Icons.notifications_none_rounded, color: AppColors.onSurface),
                        title: Text('Push Notifications', style: AppTextStyles.bodyMd),
                        value: _pushNotificationsEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (value) => setState(() => _pushNotificationsEnabled = value),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.shield_outlined, color: AppColors.onSurface),
                        title: Text('Privacy & Security', style: AppTextStyles.bodyMd),
                        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
                        onTap: () {
                          // TODO: navigate to a Privacy & Security screen
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.error),
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
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primaryContainer,
                child: Icon(_iconFor(avatarIcon), size: 50, color: AppColors.primary),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onEditTap,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        const SizedBox(height: 4),
        Text(
          'BIRTHDAY AMBASSADOR',
          style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatCard({required this.value, required this.label, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.headlineMd.copyWith(color: valueColor, fontSize: 22)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _BirthdayTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.3),
          child: Icon(Icons.cake_rounded, color: AppColors.primary),
        ),
        title: Text(name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('$dateLabel ($status)', style: AppTextStyles.bodyMd.copyWith(fontSize: 13)),
        trailing: IconButton(
          icon: Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant),
          onPressed: onSettingsTap,
        ),
      ),
    );
  }
}

class _DonationRow extends StatelessWidget {
  final String title;
  final String dateLabel;
  final double amount;

  const _DonationRow({required this.title, required this.dateLabel, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.unit),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
              Text(dateLabel, style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
          Text(
            '+₹${amount.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMd.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}