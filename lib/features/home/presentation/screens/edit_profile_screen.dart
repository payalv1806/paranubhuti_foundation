import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_text_styles.dart';
import '/core/theme/app_theme.dart';

/// Edit Profile screen — lets the user update their name (and phone, if
/// set). Saves directly to their `users/{uid}` Firestore document.
class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String? currentPhone;
  final String? currentAvatarIcon;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    this.currentPhone,
    this.currentAvatarIcon,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const List<Map<String, dynamic>> _avatarOptions = [
    {'id': 'person', 'icon': Icons.person_rounded, 'label': 'Classic'},
    {'id': 'cake', 'icon': Icons.cake_rounded, 'label': 'Birthday'},
    {'id': 'volunteer', 'icon': Icons.volunteer_activism_rounded, 'label': 'Cause'},
    {'id': 'favorite', 'icon': Icons.favorite_rounded, 'label': 'Heart'},
    {'id': 'eco', 'icon': Icons.eco_rounded, 'label': 'Green'},
    {'id': 'school', 'icon': Icons.school_rounded, 'label': 'Learn'},
    {'id': 'star', 'icon': Icons.star_rounded, 'label': 'Star'},
    {'id': 'pets', 'icon': Icons.pets_rounded, 'label': 'Care'},
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late String _selectedAvatar;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone ?? '');
    _selectedAvatar = widget.currentAvatarIcon ?? 'person';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  IconData _iconFor(String id) {
    final match = _avatarOptions.firstWhere(
      (opt) => opt['id'] == id,
      orElse: () => _avatarOptions.first,
    );
    return match['icon'] as IconData;
  }

  Future<void> _onSave() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _errorMessage = 'Name cannot be empty');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'name': newName,
          'phone': _phoneController.text.trim(),
          'avatarIcon': _selectedAvatar,
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Could not save changes: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.sectionGap,
          ),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(_iconFor(_selectedAvatar), size: 52, color: AppColors.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),

            Center(
              child: Text(
                'CHOOSE PROFILE ICON',
                style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.unit * 1.5),

            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _avatarOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.unit * 1.5),
                itemBuilder: (context, index) {
                  final opt = _avatarOptions[index];
                  final id = opt['id'] as String;
                  final icon = opt['icon'] as IconData;
                  final isSelected = _selectedAvatar == id;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                        size: 26,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            Text('NAME', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.unit),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Your name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),

            const SizedBox(height: AppSpacing.gutter),

            Text('MOBILE NUMBER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.unit),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+91 98765 43210',
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.gutter),
              Text(_errorMessage!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.error, fontSize: 13)),
            ],

            const SizedBox(height: AppSpacing.sectionGap),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}