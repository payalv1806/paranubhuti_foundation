import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();

  // Controllers for adding email
  final TextEditingController _emailController = TextEditingController();
  bool _isAddingEmail = false;
  String? _emailErrorText;

  // Controllers for publishing announcement
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isPublishing = false;

  final List<String> _categories = [
    'General',
    'Celebration',
    'Fundraiser',
    'Urgent',
    'Community Event',
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailErrorText = 'Please enter an email address.');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailErrorText = 'Enter a valid email (e.g. name@example.com).');
      return;
    }

    setState(() {
      _isAddingEmail = true;
      _emailErrorText = null;
    });

    try {
      await _adminService.addNotificationEmail(email);
      _emailController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Added $email to notification list.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _emailErrorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isAddingEmail = false);
    }
  }

  Future<void> _confirmDeleteEmail(String docId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Notification Email'),
        content: Text('Are you sure you want to remove "$email" from the announcement notification list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.removeNotificationEmail(docId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed $email from notification list.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _publishAnnouncement() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an announcement title.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter announcement message content.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      await _adminService.publishAnnouncement(
        title: title,
        content: content,
        category: _selectedCategory,
      );

      _titleController.clear();
      _contentController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Announcement published & notifications dispatched!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _confirmDeleteAnnouncement(String docId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteAnnouncement(docId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = FirebaseAuth.instance.currentUser?.email;
    final isAuthorized = AdminService.isAdmin;

    // Strict access gate: If current user is not admin, show permission denied
    if (!isAuthorized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Admin Access Required'),
          backgroundColor: AppColors.background,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sectionGap),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, size: 64, color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.gutter),
                Text('Unauthorized Access', style: AppTextStyles.headlineMd),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  'Only the authorized administrator account (${AdminService.adminEmail}) can access this dashboard.\n\nSigned in as: ${currentEmail ?? 'Anonymous / Phone User'}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Dashboard', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
            Text(
              AdminService.adminEmail,
              style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Admin',
                  style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.mail_outline_rounded), text: 'Notification Emails'),
            Tab(icon: Icon(Icons.campaign_outlined), text: 'Announcements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationEmailsTab(),
          _buildAnnouncementsTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: MANAGE NOTIFICATION EMAILS
  // ---------------------------------------------------------------------------

  Widget _buildNotificationEmailsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        // Informational banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Notification Emails',
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add additional email addresses that should automatically receive email alerts when announcements are published.\n\n⚠️ Note: Adding an email here only designates them as an alert recipient and does NOT grant administrative permissions.',
                      style: AppTextStyles.bodyMd.copyWith(fontSize: 12.5, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.gutter * 1.5),

        // Add Email Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add New Notification Email', style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  'This email will be stored in Firestore and notified upon new announcements.',
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.gutter),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'e.g. trustee@paranubhutifoundation.org',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                          errorText: _emailErrorText,
                          filled: true,
                          fillColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide(color: AppColors.outlineVariant),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => _addEmail(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isAddingEmail ? null : _addEmail,
                      icon: _isAddingEmail
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sectionGap),

        // Active Email List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Configured Recipients', style: AppTextStyles.headlineMd.copyWith(fontSize: 17)),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _adminService.getNotificationEmailsStream(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '$count email${count == 1 ? '' : 's'}',
                    style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary, fontSize: 11),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),

        // Email List Stream
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _adminService.getNotificationEmailsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(AppSpacing.sectionGap),
                child: CircularProgressIndicator(),
              ));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.sectionGap),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.mark_email_unread_outlined, size: 40, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: AppSpacing.unit),
                    Text('No additional notification emails yet.', style: AppTextStyles.bodyMd),
                    const SizedBox(height: 4),
                    Text(
                      'Add emails above to notify team members when announcements are posted.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.unit),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final email = data['email'] as String? ?? '—';
                final addedAt = (data['addedAt'] as Timestamp?)?.toDate();

                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.4),
                      child: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      email,
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      addedAt != null
                          ? 'Added on ${_formatDate(addedAt)} · Recipient only'
                          : 'Recipient only',
                      style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      tooltip: 'Remove email',
                      onPressed: () => _confirmDeleteEmail(doc.id, email),
                    ),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: AppSpacing.sectionGap),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: PUBLISH & MANAGE ANNOUNCEMENTS
  // ---------------------------------------------------------------------------

  Widget _buildAnnouncementsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        // Publish Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Publish Announcement', style: AppTextStyles.headlineMd.copyWith(fontSize: 17)),
                  ],
                ),
                const SizedBox(height: AppSpacing.gutter),

                // Category selection
                Text('CATEGORY', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary, fontSize: 11)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.gutter),

                // Title input
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Announcement Title',
                    hintText: 'e.g. Birthday Celebration Drive Update!',
                    filled: true,
                    fillColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),

                const SizedBox(height: AppSpacing.gutter),

                // Content input
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Announcement Message',
                    hintText: 'Enter details of the announcement here...',
                    filled: true,
                    fillColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),

                const SizedBox(height: AppSpacing.gutter),

                // Delivery info
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _adminService.getNotificationEmailsStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.send_rounded, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Will be visible to all app users and queued for delivery to $count notification email${count == 1 ? '' : 's'}.',
                              style: AppTextStyles.bodyMd.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.gutter),

                // Publish Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isPublishing ? null : _publishAnnouncement,
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.publish_rounded, size: 20),
                    label: Text(
                      _isPublishing ? 'Publishing...' : 'Publish Announcement',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sectionGap),

        // Recent Announcements Feed Header
        Text('Published Announcements', style: AppTextStyles.headlineMd.copyWith(fontSize: 17)),
        const SizedBox(height: AppSpacing.gutter),

        // Stream of Announcements
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _adminService.getAnnouncementsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(AppSpacing.sectionGap),
                child: CircularProgressIndicator(),
              ));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.sectionGap),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text('No announcements published yet.', style: AppTextStyles.bodyMd),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.gutter),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final title = data['title'] as String? ?? 'Untitled';
                final content = data['content'] as String? ?? '';
                final category = data['category'] as String? ?? 'General';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _colorForCategory(category).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: AppTextStyles.labelCaps.copyWith(
                                  color: _colorForCategory(category),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (createdAt != null)
                              Text(
                                _formatDate(createdAt),
                                style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Delete announcement',
                              onPressed: () => _confirmDeleteAnnouncement(doc.id, title),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(title, style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(content, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: AppSpacing.sectionGap),
      ],
    );
  }

  Color _colorForCategory(String category) {
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
}
