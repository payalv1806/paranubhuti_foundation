import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/services/admin_service.dart';
import 'package:paranubhutifoundation/features/admin/presentation/screens/admin_dashboard_screen.dart';

/// Notifications & Announcements screen.
/// Offers two tabs:
/// 1. Community Announcements: Official announcements published by Paranubhuti Foundation admin.
/// 2. Birthday Reminders: Live reminders computed from the `birthdays` collection.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isAdmin = AdminService.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Updates & Notifications', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
        actions: [
          if (isAdmin)
            TextButton.icon(
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppColors.primary),
              label: Text('Admin', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.campaign_rounded), text: 'Announcements'),
            Tab(icon: Icon(Icons.cake_rounded), text: 'Birthday Reminders'),
          ],
        ),
      ),
      body: uid == null
          ? Center(child: Text('Not signed in', style: AppTextStyles.bodyMd))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnnouncementsTab(),
                _buildBirthdayRemindersTab(uid),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: ANNOUNCEMENTS FEED
  // ---------------------------------------------------------------------------

  Widget _buildAnnouncementsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sectionGap),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 56,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppSpacing.gutter),
                  Text('No Announcements Yet', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(
                    'Stay tuned! Important foundation updates and birthday campaigns will appear here.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.unit * 2,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final title = data['title'] as String? ?? 'Announcement';
            final content = data['content'] as String? ?? '';
            final category = data['category'] as String? ?? 'General';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _categoryColor(category).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 8, color: _categoryColor(category)),
                                const SizedBox(width: 5),
                                Text(
                                  category.toUpperCase(),
                                  style: AppTextStyles.labelCaps.copyWith(
                                    color: _categoryColor(category),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (createdAt != null)
                            Text(
                              _formatDate(createdAt),
                              style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: AppTextStyles.headlineMd.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        content,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurface.withValues(alpha: 0.85),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Paranubhuti Foundation Official',
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Celebration':
        return AppColors.tertiary;
      case 'Urgent':
        return AppColors.error;
      case 'Fundraiser':
        return AppColors.secondary;
      case 'Community Event':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ---------------------------------------------------------------------------
  // TAB 2: BIRTHDAY REMINDERS (Preserved from existing implementation)
  // ---------------------------------------------------------------------------

  Widget _buildBirthdayRemindersTab(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('birthdays')
          .where('ownerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reminders = <_BirthdayReminder>[];
        for (final doc in snapshot.data!.docs) {
          final data = doc.data();
          final dobTs = data['dob'] as Timestamp?;
          if (dobTs == null) continue;

          final reminderDaysBefore = (data['reminderDaysBefore'] as num?)?.toInt() ?? 0;
          final next = _nextOccurrence(dobTs.toDate());
          final daysUntil = _daysUntil(next);

          reminders.add(_BirthdayReminder(
            personName: data['personName'] as String? ?? '—',
            relation: data['relation'] as String? ?? 'other',
            nextOccurrence: next,
            daysUntil: daysUntil,
            reminderDaysBefore: reminderDaysBefore,
            isDue: reminderDaysBefore > 0 && daysUntil <= reminderDaysBefore,
          ));
        }

        reminders.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
        final due = reminders.where((r) => r.isDue).toList();
        final upcoming = reminders.where((r) => !r.isDue).toList();

        if (reminders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sectionGap),
              child: Text(
                'No birthdays registered yet.',
                style: AppTextStyles.bodyMd,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.unit * 2,
          ),
          children: [
            if (due.isNotEmpty) ...[
              Text('DUE NOW', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
              const SizedBox(height: AppSpacing.gutter),
              ...due.map((r) => _ReminderTile(reminder: r, highlighted: true)),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
            if (upcoming.isNotEmpty) ...[
              Text('UPCOMING', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.gutter),
              ...upcoming.map((r) => _ReminderTile(reminder: r, highlighted: false)),
            ],
          ],
        );
      },
    );
  }

  /// Next calendar occurrence of [dob]'s month/day — this year if it hasn't
  /// happened yet, otherwise next year.
  static DateTime _nextOccurrence(DateTime dob) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(today.year, dob.month, dob.day);
    if (next.isBefore(today)) {
      next = DateTime(today.year + 1, dob.month, dob.day);
    }
    return next;
  }

  static int _daysUntil(DateTime next) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return next.difference(today).inDays;
  }
}

class _BirthdayReminder {
  final String personName;
  final String relation;
  final DateTime nextOccurrence;
  final int daysUntil;
  final int reminderDaysBefore;
  final bool isDue;

  _BirthdayReminder({
    required this.personName,
    required this.relation,
    required this.nextOccurrence,
    required this.daysUntil,
    required this.reminderDaysBefore,
    required this.isDue,
  });
}

class _ReminderTile extends StatelessWidget {
  final _BirthdayReminder reminder;
  final bool highlighted;

  const _ReminderTile({required this.reminder, required this.highlighted});

  String get _dateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = reminder.nextOccurrence;
    return '${months[d.month - 1]} ${d.day}';
  }

  String get _countdownLabel {
    if (reminder.daysUntil == 0) return 'Today!';
    if (reminder.daysUntil == 1) return 'Tomorrow';
    return 'In ${reminder.daysUntil} days';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Card(
        color: highlighted ? AppColors.primaryContainer.withValues(alpha: 0.3) : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: highlighted
                ? AppColors.primary
                : AppColors.surfaceContainerHigh,
            child: Icon(
              Icons.cake_rounded,
              color: highlighted ? Colors.white : AppColors.onSurfaceVariant,
            ),
          ),
          title: Text(
            reminder.relation == 'self' ? 'Your birthday' : reminder.personName,
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '$_dateLabel · $_countdownLabel',
            style: AppTextStyles.bodyMd.copyWith(fontSize: 13),
          ),
          trailing: highlighted
              ? Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 20)
              : null,
        ),
      ),
    );
  }
}