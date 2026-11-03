import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_text_styles.dart';
import '/core/theme/app_theme.dart';

/// Edit Profile screen — lets the user update their name, phone,
/// upload a custom photo from device gallery/camera, OR pick a customized avatar icon.
class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String? currentPhone;
  final String? currentAvatarIcon;
  final String? currentPhotoUrl;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    this.currentPhone,
    this.currentAvatarIcon,
    this.currentPhotoUrl,
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
  String? _selectedLocalImagePath;
  String? _photoUrl;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone ?? '');
    _selectedAvatar = widget.currentAvatarIcon ?? 'person';
    _photoUrl = widget.currentPhotoUrl ?? FirebaseAuth.instance.currentUser?.photoURL;
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() {
          _selectedLocalImagePath = picked.path;
          _selectedAvatar = 'custom_photo';
        });
      }
    } catch (e) {
      debugPrint('[EditProfile] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _onSave() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _errorMessage = 'Name cannot be empty');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String? uploadedPhotoUrl = _photoUrl;

      // 1. Upload photo if selected from device
      if (_selectedLocalImagePath != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref('users/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await ref.putFile(File(_selectedLocalImagePath!));
          uploadedPhotoUrl = await ref.getDownloadURL();
          await user.updatePhotoURL(uploadedPhotoUrl);
        } catch (storageError) {
          debugPrint('[EditProfile] Firebase Storage upload error ($storageError). Falling back to inline base64 image data.');
          final bytes = await File(_selectedLocalImagePath!).readAsBytes();
          final b64 = base64Encode(bytes);
          uploadedPhotoUrl = 'data:image/jpeg;base64,$b64';
        }
      } else if (_selectedAvatar != 'custom_photo') {
        // If user explicitly picked an icon instead of photo, clear custom photo
        uploadedPhotoUrl = null;
      }

      await user.updateDisplayName(newName);

      // 2. Save directly to Firestore users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'name': newName,
          'phone': _phoneController.text.trim(),
          'avatarIcon': _selectedAvatar,
          'photoUrl': uploadedPhotoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
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

  Widget _buildAvatarPreview() {
    if (_selectedLocalImagePath != null) {
      return CircleAvatar(
        radius: 52,
        backgroundColor: AppColors.primaryContainer,
        backgroundImage: FileImage(File(_selectedLocalImagePath!)),
      );
    } else if (_selectedAvatar == 'custom_photo' && _photoUrl != null && _photoUrl!.isNotEmpty) {
      if (_photoUrl!.startsWith('data:image')) {
        try {
          final bytes = base64Decode(_photoUrl!.split(',').last);
          return CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      }
      return CircleAvatar(
        radius: 52,
        backgroundColor: AppColors.primaryContainer,
        backgroundImage: NetworkImage(_photoUrl!),
      );
    }

    return CircleAvatar(
      radius: 52,
      backgroundColor: AppColors.primaryContainer,
      child: Icon(_iconFor(_selectedAvatar), size: 52, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
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
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: _buildAvatarPreview(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Upload Photo from Gallery'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.gutter),

            Center(
              child: Text(
                'OR CHOOSE A CUSTOMIZED ICON',
                style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary, fontSize: 11),
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
                  final isSelected = _selectedAvatar == id && _selectedLocalImagePath == null;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = id;
                        _selectedLocalImagePath = null;
                      });
                    },
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
              decoration: InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),

            Text('PHONE NUMBER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.unit),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter your phone number',
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.gutter),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: AppSpacing.sectionGap),

            ElevatedButton(
              onPressed: _isSaving ? null : _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
