import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/models/cause_model.dart';
import 'package:paranubhutifoundation/shared/widgets/appbar_screen.dart';
import 'payment_details_screen.dart';

/// Donate screen — "Make a Birthday Gift".
/// Vertical list of cause cards (icon badge + title + description + radio),
/// fetched live from Firestore `causes`, followed by a gift-amount picker
/// (3 circular presets + custom amount), then "Continue to Payment".
class DonateScreen extends StatefulWidget {
  final String? preselectedCauseId;

  const DonateScreen({super.key, this.preselectedCauseId});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  static const List<_AmountOption> _presetAmounts = [
    _AmountOption(amount: 100, label: 'Small'),
    _AmountOption(amount: 500, label: 'Popular'),
    _AmountOption(amount: 1000, label: 'Large'),
  ];

  String? _selectedCauseId;
  double? _selectedPresetAmount;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCauseId = widget.preselectedCauseId;
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  double? get _finalAmount {
    final custom = double.tryParse(_customAmountController.text);
    if (custom != null && custom > 0) return custom;
    return _selectedPresetAmount;
  }

  bool get _canContinue => _selectedCauseId != null && _finalAmount != null && _finalAmount! > 0;

  void _selectPreset(double amount) {
    setState(() {
      _selectedPresetAmount = amount;
      _customAmountController.clear();
    });
  }

  void _onContinue(List<CauseModel> causes) {
    final cause = causes.firstWhere((c) => c.id == _selectedCauseId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentDetailsScreen(
          causeId: cause.id,
          causeCategory: cause.tag,
          causeTitle: cause.title,
          amount: _finalAmount!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBarScreen(),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('causes').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sectionGap),
                  child: Text(
                    'Could not load causes. Please try again.',
                    style: AppTextStyles.bodyMd,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final causes = snapshot.data!.docs.map(CauseModel.fromFirestore).toList();

            if (causes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sectionGap),
                  child: Text(
                    'No causes available right now.',
                    style: AppTextStyles.bodyMd,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // Default to the preselected cause if it exists in the loaded
            // list, otherwise the first cause, but only once (don't stomp on
            // a selection the user already made by tapping a different card).
            _selectedCauseId ??= causes.any((c) => c.id == widget.preselectedCauseId)
                ? widget.preselectedCauseId
                : causes.first.id;

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.unit * 2,
              ),
              children: [
                Text('Make a Birthday Gift', style: AppTextStyles.displayLgMobile.copyWith(fontSize: 26)),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  "Transform your celebration into real-world impact. Choose a cause close to your heart.",
                  style: AppTextStyles.bodyMd,
                ),

                const SizedBox(height: AppSpacing.sectionGap),

                Text('CHOOSE A CAUSE', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
                const SizedBox(height: AppSpacing.gutter),

                ...causes.map(
                      (cause) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
                    child: _CauseListTile(
                      cause: cause,
                      isSelected: cause.id == _selectedCauseId,
                      onTap: () => setState(() => _selectedCauseId = cause.id),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.gutter + AppSpacing.unit),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SELECT GIFT AMOUNT', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
                        const SizedBox(height: AppSpacing.gutter),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _presetAmounts
                              .map((option) => _AmountCircle(
                            option: option,
                            selected: _selectedPresetAmount == option.amount &&
                                _customAmountController.text.isEmpty,
                            onTap: () => _selectPreset(option.amount),
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),
                        Text('Custom Amount (₹)', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: AppSpacing.unit),
                        TextField(
                          controller: _customAmountController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(hintText: 'Enter other amount'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canContinue ? () => _onContinue(causes) : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Continue to Payment'),
                        SizedBox(width: AppSpacing.unit),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Horizontal cause card: colored icon badge, title, description, and a
/// radio-style selection indicator on the right.
class _CauseListTile extends StatelessWidget {
  final CauseModel cause;
  final bool isSelected;
  final VoidCallback onTap;

  const _CauseListTile({required this.cause, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: isSelected ? cause.badgeColor.withValues(alpha: 0.18) : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cause.badgeColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(cause.icon, color: AppColors.onSurface, size: 22),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cause.title, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    cause.description ?? '',
                    style: AppTextStyles.bodyMd.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.unit),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountOption {
  final double amount;
  final String label;
  const _AmountOption({required this.amount, required this.label});
}

/// Circular selectable gift-amount button (e.g. "$50 / Popular").
class _AmountCircle extends StatelessWidget {
  final _AmountOption option;
  final bool selected;
  final VoidCallback onTap;

  const _AmountCircle({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.primaryContainer.withValues(alpha: 0.25) : AppColors.surfaceContainerLowest,
              border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant, width: selected ? 2 : 1),
            ),
            alignment: Alignment.center,
            child: Text(
              '₹${option.amount.toStringAsFixed(0)}',
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            option.label,
            style: AppTextStyles.labelCaps.copyWith(
              fontSize: 10,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}