import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';

class VoulenterScreen extends StatelessWidget {
  const VoulenterScreen({super.key});

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
        title: Text('Volunteer With Us', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.sectionGap,
          ),
          children: [
            const Text('🤝', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.gutter),
            Text('Join the Mission', style: AppTextStyles.displayLgMobile.copyWith(fontSize: 26)),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Give your time and talents to bring smiles to those in need on their special days.',
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.school_rounded, color: AppColors.primary),
                ),
                title: Text('Teach & Mentor', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                subtitle: const Text('Volunteer in children education and skill building workshops.'),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondaryContainer,
                  child: Icon(Icons.cake_rounded, color: AppColors.secondary),
                ),
                title: Text('Birthday Event Host', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                subtitle: const Text('Help coordinate gift distributions and celebration drives.'),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.tertiaryContainer,
                  child: Icon(Icons.eco_rounded, color: AppColors.tertiary),
                ),
                title: Text('Green Birthday Drive', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                subtitle: const Text('Plant saplings and lead local tree plantation activities.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
