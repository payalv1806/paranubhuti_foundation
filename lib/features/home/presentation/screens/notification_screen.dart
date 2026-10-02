import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';

/// Notifications screen — shows birthday reminders computed from the
/// `birthdays` collection (`ownerId == uid`), using each doc's `dob` and
/// `reminderDaysBefore` to figure out what's due soon.
///
/// This is computed live on open (no background push here) — it answers
/// "what should I be reminded about right now", not a persisted
/// notification log.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
      ),
      body: uid == null
          ? Center(child: Text('Not signed in', style: AppTextStyles.bodyMd))
          : SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
        ),
      ),
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