import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/notification_screen.dart';

/// Shared app bar used across every bottom-nav tab (Home, Causes, Profile).
/// Shows the "🎉 Birthday for cause" title and a notification bell with a live
/// red badge counting birthdays currently inside their reminder window.
///
/// Usage in any screen:
///   appBar: const AppBarScreen(),
class AppBarScreen extends StatelessWidget implements PreferredSizeWidget {
  const AppBarScreen({super.key});

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
              errorBuilder: (_, _, _) => const Text('🎉 ', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Birthday for cause',
            style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontSize: 18),
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