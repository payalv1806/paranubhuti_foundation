import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized service handling Admin authorization and Announcement & Notification Email operations.
///
/// Security note:
/// - Only the account with email [adminEmail] is authorized to perform admin actions.
/// - Adding an email address to [notification_emails] does NOT confer admin privileges.
class AdminService {
  static const String adminEmail = 'info@paranubhutifoundation.org';

  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns true if the currently authenticated user's email matches [adminEmail].
  static bool get isAdmin {
    final currentEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase().trim();
    return currentEmail == adminEmail.toLowerCase();
  }

  /// Current user's email or null.
  static String? get currentEmail => FirebaseAuth.instance.currentUser?.email;

  // ---------------------------------------------------------------------------
  // NOTIFICATION EMAILS (Recipients only - NO admin permissions granted)
  // ---------------------------------------------------------------------------

  /// Stream of additional notification email documents.
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationEmailsStream() {
    return _firestore
        .collection('notification_emails')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  /// Adds a new notification recipient email address.
  /// Throws an exception if current user is not admin or if email is invalid/already exists.
  Future<void> addNotificationEmail(String email) async {
    if (!isAdmin) {
      throw Exception('Unauthorized: Only $adminEmail can manage notification emails.');
    }

    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedEmail)) {
      throw Exception('Please provide a valid email address.');
    }

    // Check for duplicate
    final existing = await _firestore
        .collection('notification_emails')
        .where('email', isEqualTo: trimmedEmail)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('This email is already in the notification list.');
    }

    await _firestore.collection('notification_emails').add({
      'email': trimmedEmail,
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': _auth.currentUser?.email ?? adminEmail,
      'role': 'recipient', // Explicitly marked as recipient only
    });
  }

  /// Removes an email address from the notification list.
  Future<void> removeNotificationEmail(String docId) async {
    if (!isAdmin) {
      throw Exception('Unauthorized: Only $adminEmail can manage notification emails.');
    }
    await _firestore.collection('notification_emails').doc(docId).delete();
  }

  // ---------------------------------------------------------------------------
  // ANNOUNCEMENTS
  // ---------------------------------------------------------------------------

  /// Stream of announcements ordered by latest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> getAnnouncementsStream() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Publishes a new announcement.
  /// 1. Saves announcement doc into `announcements` collection for all app users.
  /// 2. Queries all recipient emails in `notification_emails`.
  /// 3. Queues email dispatch in `mail` collection (processed securely by Firebase Trigger Email / backend).
  Future<void> publishAnnouncement({
    required String title,
    required String content,
    String category = 'General',
  }) async {
    if (!isAdmin) {
      throw Exception('Unauthorized: Only $adminEmail can publish announcements.');
    }

    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();

    if (trimmedTitle.isEmpty) throw Exception('Announcement title cannot be empty.');
    if (trimmedContent.isEmpty) throw Exception('Announcement content cannot be empty.');

    // 1. Create announcement document
    final announcementRef = await _firestore.collection('announcements').add({
      'title': trimmedTitle,
      'content': trimmedContent,
      'category': category,
      'authorEmail': adminEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Fetch all recipient notification emails
    final recipientsSnapshot = await _firestore.collection('notification_emails').get();
    final recipientEmails = recipientsSnapshot.docs
        .map((d) => (d.data()['email'] as String?)?.trim().toLowerCase())
        .where((e) => e != null && e.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    // 3. If there are notification emails, create a secure dispatch document in `mail` collection
    // No private API keys or SMTP passwords are exposed to the client.
    if (recipientEmails.isNotEmpty) {
      await _firestore.collection('mail').add({
        'to': recipientEmails,
        'announcementId': announcementRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'message': {
          'subject': '📢 Paranubhuti Foundation Announcement: $trimmedTitle',
          'text': '$trimmedTitle\n\n$trimmedContent\n\n- Paranubhuti Foundation Team',
          'html': '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
              <h2 style="color: #6750A4; margin-bottom: 8px;">Paranubhuti Foundation</h2>
              <p style="font-size: 13px; color: #757575; margin-top: 0;">Birthday for a Cause — Announcement</p>
              <hr style="border: none; border-top: 1px solid #eeeeee; margin: 16px 0;" />
              <h3 style="color: #1c1b1f; margin-bottom: 12px;">$trimmedTitle</h3>
              <div style="font-size: 15px; line-height: 1.6; color: #49454f; white-space: pre-wrap;">$trimmedContent</div>
              <hr style="border: none; border-top: 1px solid #eeeeee; margin: 24px 0 16px 0;" />
              <p style="font-size: 12px; color: #8c8c8c;">You are receiving this notification because your email is registered with Paranubhuti Foundation's announcement updates.</p>
            </div>
          ''',
        },
      });
    }
  }

  /// Deletes an announcement.
  Future<void> deleteAnnouncement(String docId) async {
    if (!isAdmin) {
      throw Exception('Unauthorized: Only $adminEmail can delete announcements.');
    }
    await _firestore.collection('announcements').doc(docId).delete();
  }
}
