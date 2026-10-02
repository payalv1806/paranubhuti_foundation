import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';

class CreateFundraiserScreen extends StatefulWidget {
  const CreateFundraiserScreen({super.key});

  @override
  State<CreateFundraiserScreen> createState() => _CreateFundraiserScreenState();
}

class _CreateFundraiserScreenState extends State<CreateFundraiserScreen> {
  static const List<Map<String, dynamic>> _causes = [
    {
      'id': 'education',
      'title': 'Education Support',
      'icon': Icons.school_rounded,
      'color': AppColors.secondaryContainer,
      'onColor': AppColors.onSecondaryContainer,
    },
    {
      'id': 'health',
      'title': 'Health Support',
      'icon': Icons.favorite_rounded,
      'color': AppColors.tertiaryContainer,
      'onColor': AppColors.onTertiaryContainer,
    },
    {
      'id': 'women',
      'title': 'Women Empowerment',
      'icon': Icons.groups_rounded,
      'color': AppColors.primaryContainer,
      'onColor': AppColors.onPrimaryContainer,
    },
    {
      'id': 'environment',
      'title': 'Environment Drive',
      'icon': Icons.eco_rounded,
      'color': AppColors.inversePrimary,
      'onColor': AppColors.onPrimary,
    },
  ];

  static const List<double> _presetGoals = [2500, 5000, 10000, 25000];

  late String _selectedCauseId;
  late double _selectedGoal;
  final TextEditingController _customGoalController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  DateTime? _celebrationDate;
  bool _isSaving = false;
  String? _errorMessage;
  bool _fundraiserCreated = false;
  String? _createdFundraiserId;

  @override
  void initState() {
    super.initState();
    _selectedCauseId = _causes.first['id'] as String;
    _selectedGoal = _presetGoals[1]; // ₹5,000 default
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'My';
    _titleController.text = "$userName's Birthday Fundraiser";
    _messageController.text =
        "Instead of gifts this year, I'm dedicating my birthday to support this cause. Every small contribution helps make a real difference!";
  }

  @override
  void dispose() {
    _customGoalController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  double get _finalGoal {
    final custom = double.tryParse(_customGoalController.text.trim());
    if (custom != null && custom > 0) return custom;
    return _selectedGoal;
  }

  Map<String, dynamic> get _currentCause =>
      _causes.firstWhere((c) => c['id'] == _selectedCauseId);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _celebrationDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _celebrationDate = picked);
    }
  }

  Future<void> _createFundraiser() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a fundraiser title');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _errorMessage = 'Please log in to launch a fundraiser');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final docRef = await FirebaseFirestore.instance.collection('fundraisers').add({
        'userId': user.uid,
        'creatorName': user.displayName ?? 'Supporter',
        'title': title,
        'causeId': _selectedCauseId,
        'causeTitle': _currentCause['title'],
        'goalAmount': _finalGoal,
        'totalRaised': 0.0,
        'message': _messageController.text.trim(),
        'celebrationDate': _celebrationDate != null ? Timestamp.fromDate(_celebrationDate!) : null,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _fundraiserCreated = true;
        _createdFundraiserId = docRef.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not save fundraiser: $e';
      });
    }
  }

  void _shareFundraiser() {
    final title = _titleController.text.trim();
    final causeTitle = _currentCause['title'];
    final shareText =
        "🎉 Support $title for $causeTitle! Join me in turning my birthday celebration into life-changing impact. Goal: ₹${_finalGoal.toStringAsFixed(0)}.\n\nContribute here: https://paranubhutifoundation.org/fundraiser/${_createdFundraiserId ?? 'new'}";

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fundraiser link copied to clipboard! Ready to share.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cause = _currentCause;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Birthday Fundraiser Plan', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.unit * 2,
          ),
          children: [
            Text('Start a Giving Celebration', style: AppTextStyles.displayLgMobile.copyWith(fontSize: 24)),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Set a goal, invite friends & family, and celebrate your special day by creating impact.',
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Live Preview Card
            Text('LIVE PREVIEW', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.gutter),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter * 1.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: cause['color'] as Color,
                          child: Icon(cause['icon'] as IconData, color: cause['onColor'] as Color),
                        ),
                        const SizedBox(width: AppSpacing.gutter),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (cause['title'] as String).toUpperCase(),
                                style: AppTextStyles.labelCaps.copyWith(fontSize: 10, color: AppColors.primary),
                              ),
                              Text(
                                _titleController.text.isEmpty ? 'Birthday Fundraiser' : _titleController.text,
                                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    Text(
                      _messageController.text,
                      style: AppTextStyles.bodyMd.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    LinearProgressIndicator(
                      value: 0.05,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹0 raised', style: AppTextStyles.bodyMd.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Goal: ₹${_finalGoal.toStringAsFixed(0)}', style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            // Select Cause
            Text('1. CHOOSE CAUSE', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.gutter),
            Wrap(
              spacing: AppSpacing.gutter,
              runSpacing: AppSpacing.gutter,
              children: _causes.map((c) {
                final isSelected = c['id'] == _selectedCauseId;
                return ChoiceChip(
                  avatar: Icon(c['icon'] as IconData, size: 16, color: isSelected ? Colors.white : AppColors.primary),
                  label: Text(c['title'] as String),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _selectedCauseId = c['id'] as String),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            // Target Goal
            Text('2. TARGET GOAL AMOUNT', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.gutter),
            Row(
              children: _presetGoals.map((g) {
                final isSelected = _selectedGoal == g && _customGoalController.text.isEmpty;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: isSelected ? AppColors.primaryContainer : Colors.transparent,
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedGoal = g;
                          _customGoalController.clear();
                        });
                      },
                      child: Text(
                        '₹${g.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _customGoalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Or enter custom goal (₹)',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            // Fundraiser Title & Celebration Date
            Text('3. CELEBRATION DETAILS', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Fundraiser Title',
                prefixIcon: Icon(Icons.cake_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.gutter),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.gutter),
                    Text(
                      _celebrationDate == null
                          ? 'Select celebration date (optional)'
                          : 'Celebration: ${_celebrationDate!.day}/${_celebrationDate!.month}/${_celebrationDate!.year}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: _celebrationDate == null ? AppColors.onSurfaceVariant : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Personal Dedication Message',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.gutter),
              Text(_errorMessage!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.error, fontSize: 13)),
            ],

            const SizedBox(height: AppSpacing.sectionGap),

            if (_fundraiserCreated) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.gutter * 1.2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
                    const SizedBox(height: AppSpacing.unit),
                    Text(
                      'Fundraiser Created Successfully! 🎉',
                      style: AppTextStyles.headlineMd.copyWith(fontSize: 18, color: Colors.green.shade800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.unit),
                    Text(
                      'Share this link with your friends and family so they can donate to your celebration.',
                      style: AppTextStyles.bodyMd.copyWith(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                        label: const Text('Share Fundraiser Link', style: TextStyle(color: Colors.white)),
                        onPressed: _shareFundraiser,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _createFundraiser,
                  icon: _isSaving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.rocket_launch_rounded),
                  label: Text(_isSaving ? 'Launching...' : 'Create & Launch Fundraiser'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sectionGap),
          ],
        ),
      ),
    );
  }
}
