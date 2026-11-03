import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/services/auth_service.dart';
import 'package:paranubhutifoundation/authentication/login_screen.dart';

/// Privacy & Security Screen
/// A clean, streamlined privacy and security settings page containing only
/// functional, necessary settings that work directly with the project:
/// 1. Login & Security (Account credential info, Password reset)
/// 2. Privacy Settings (Anonymous donations, Public birthday visibility)
/// 3. Policies & Terms (Privacy policy, Terms of service)
/// 4. Account Deletion (Permanent account & data deletion)
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  String? get _uid => _auth.currentUser?.uid;
  User? get _currentUser => _auth.currentUser;

  Future<void> _updateFirestoreField(String field, dynamic value) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Preference updated successfully'),
              ],
            ),
            backgroundColor: AppColors.tertiary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DIALOGS & SHEETS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Password reset dialog with scrollable content to prevent keyboard overflow
  void _showPasswordResetDialog(String defaultEmail) {
    final controller = TextEditingController(text: defaultEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Reset Password',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email address to receive a secure password reset link:',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              final targetEmail = controller.text.trim();
              if (targetEmail.isEmpty || !targetEmail.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid email address')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await _authService.sendPasswordResetEmail(targetEmail);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset link sent to $targetEmail. Check your inbox!'),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send reset link: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            ),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  /// Policy and Terms bottom sheet with draggable scroll to prevent overflow
  void _showPolicySheet({required String title, required String content, required IconData icon}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter * 1.2, vertical: AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.headlineMd.copyWith(fontSize: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutter),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.gutter),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    content,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Permanent Account Deletion Dialog with keyboard overflow safety
  void _showDeleteAccountDialog() {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isConfirmed = confirmController.text.trim().toUpperCase() == 'DELETE';

          return AlertDialog(
            scrollable: true,
            backgroundColor: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(color: AppColors.error, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to permanently delete your account? All your registered birthdays and profile data will be permanently deleted.',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.gutter),
                Text(
                  'Type "DELETE" to confirm:',
                  style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmController,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Type DELETE',
                    hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
              ),
              ElevatedButton(
                onPressed: !isConfirmed
                    ? null
                    : () async {
                        Navigator.pop(dialogCtx);
                        final uid = _uid;
                        try {
                          if (uid != null) {
                            // Delete birthdays registered by this user
                            final birthdays = await _firestore.collection('birthdays').where('ownerId', isEqualTo: uid).get();
                            for (final doc in birthdays.docs) {
                              await doc.reference.delete();
                            }
                            // Delete user document in Firestore
                            await _firestore.collection('users').doc(uid).delete();
                          }
                          // Delete Firebase Auth user
                          await _currentUser?.delete();
                          await _authService.signOut();

                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account successfully deleted.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please log out and log in again before deleting: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD METHOD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy & Security',
          style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: uid == null
              ? null
              : _firestore.collection('users').doc(uid).snapshots(),
          builder: (context, userSnap) {
            final userData = userSnap.data?.data() ?? {};
            final isAnonymous = userData['isAnonymousDonor'] as bool? ?? false;
            final isBirthdayPublic = userData['isBirthdayPublic'] as bool? ?? true;

            final phone = userData['phone'] as String? ?? _currentUser?.phoneNumber;
            final email = userData['email'] as String? ?? _currentUser?.email ?? '';

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.unit * 1.5,
              ),
              children: [
                // 1. COMPACT TOP BANNER (Overflow-safe)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Account Protection',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Manage your login security and donation privacy.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap * 0.5),

                // 2. SECTION: LOGIN & SECURITY
                _buildSectionHeader(
                  icon: Icons.lock_outline_rounded,
                  title: 'LOGIN & SECURITY',
                ),
                Card(
                  child: Column(
                    children: [
                      // Current credentials indicator
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(Icons.verified_user_rounded, color: Colors.green.shade700, size: 20),
                        ),
                        title: Text(
                          phone != null && phone.isNotEmpty ? phone : (email.isNotEmpty ? email : 'Signed In'),
                          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Authenticated Account',
                          style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: Colors.green.shade300, width: 0.8),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // Reset password option
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          'Change / Reset Password',
                          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Receive a password reset link on email',
                          style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
                        onTap: () => _showPasswordResetDialog(email),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap * 0.5),

                // 3. SECTION: PRIVACY PREFERENCES
                _buildSectionHeader(
                  icon: Icons.visibility_outlined,
                  title: 'PRIVACY PREFERENCES',
                ),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 4),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.visibility_off_outlined, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          'Anonymous Donations',
                          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Hide your name on public donor lists. Displayed as "Kind Supporter".',
                          style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        value: isAnonymous,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => _updateFirestoreField('isAnonymousDonor', val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 4),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.cake_outlined, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          'Public Birthday Feed',
                          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Show your registered birthday on community celebration campaigns',
                          style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        value: isBirthdayPublic,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => _updateFirestoreField('isBirthdayPublic', val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap * 0.5),

                // 4. SECTION: POLICIES & TERMS
                _buildSectionHeader(
                  icon: Icons.policy_outlined,
                  title: 'ABOUT & LEGAL',
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.policy_outlined, color: AppColors.tertiary, size: 20),
                        ),
                        title: Text(
                          'Privacy Policy',
                          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'How we protect and handle your data',
                          style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
                        onTap: () => _showPolicySheet(
                          title: 'Privacy Policy',
                          icon: Icons.policy_rounded,
                          content: _kPrivacyPolicyText,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.description_outlined, color: AppColors.tertiary, size: 20),
                        ),
                        title: Text(
                          'Terms of Service',
                          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Guidelines for donations and certificates',
                          style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
                        onTap: () => _showPolicySheet(
                          title: 'Terms of Service',
                          icon: Icons.description_rounded,
                          content: _kTermsOfServiceText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap * 0.5),

                // 5. SECTION: ACCOUNT ACTIONS (Danger zone)
                _buildSectionHeader(
                  icon: Icons.warning_amber_rounded,
                  title: 'ACCOUNT ACTIONS',
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    ),
                    title: Text(
                      'Delete Account Permanently',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Permanently erase your registered birthdays and account data',
                      style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                    onTap: _showDeleteAccountDialog,
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap * 0.6),

                // Bottom App Version
                Center(
                  child: Text(
                    'Parānubhūti Foundation v1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.unit * 2),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Categorized section header (Clean & compact)
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POLICY & COMPLIANCE TEXT CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const String _kPrivacyPolicyText = '''
Parānubhūti Foundation Privacy Policy

1. Information We Collect:
• Account Information: Name, phone number, and email.
• Celebration Data: Birthday dates and relations entered for cause celebration reminders.
• Donation Records: Transaction amounts, cause identifiers, and payment reference numbers. (Note: We never store card details or UPI PINs; all payments are processed through Razorpay).

2. How We Use Your Data:
• To send celebration notifications and birthday cause reminders.
• To issue legitimate donation receipts and 80G certificates.
• To showcase fundraiser progress and community impact.

3. Sharing & Privacy Controls:
We never sell your personal information. You can choose to keep your donations anonymous and hide your birthday from public celebration feeds using the switches on this page.

For questions, contact: privacy@paranubhutifoundation.org
''';

const String _kTermsOfServiceText = '''
Terms of Service — Parānubhūti Foundation

1. Introduction:
By using the Parānubhūti Foundation app, you agree to these terms and all applicable laws in India.

2. Cause Contributions:
All donations made through the platform are directed towards verified social welfare initiatives. Contributions are voluntary.

3. 80G Tax Exemption:
Donations qualify for tax exemption under Section 80G of the Indian Income Tax Act. Official digital certificates are issued upon payment verification.

4. Account Responsibility:
Users agree to provide accurate celebration dates and refrain from submitting fraudulent fundraisers.
''';
