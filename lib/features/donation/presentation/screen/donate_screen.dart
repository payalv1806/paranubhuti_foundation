import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/models/cause_model.dart';
import 'package:paranubhutifoundation/services/payment_service.dart';
import 'package:paranubhutifoundation/shared/widgets/appbar_screen.dart';
import 'thank_you_screen.dart';

/// Donate screen — "Make a Birthday Gift".
/// Vertical list of cause cards (icon badge + title + description + radio),
/// fetched live from Firestore `causes`, followed by a gift-amount picker
/// (3 circular presets + custom amount), anonymous donation toggle, and
/// direct 1-tap Razorpay native payment checkout (bypassing redundant payment details page).
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

  bool _isAnonymous = false;
  bool _isProcessing = false;
  CauseModel? _activeCause;

  late final PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    _selectedCauseId = widget.preselectedCauseId;
    _paymentService = PaymentService()
      ..onSuccess = _onPaymentSuccess
      ..onError = _onPaymentError;
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  double? get _finalAmount {
    final custom = double.tryParse(_customAmountController.text);
    if (custom != null && custom > 0) return custom;
    return _selectedPresetAmount;
  }

  bool get _canContinue =>
      _selectedCauseId != null &&
      _finalAmount != null &&
      _finalAmount! >= 100 &&
      !_isProcessing;

  void _selectPreset(double amount) {
    setState(() {
      _selectedPresetAmount = amount;
      _customAmountController.clear();
    });
  }

  Future<void> _onProceedToPay(List<CauseModel> causes) async {
    if (!_canContinue) return;

    final cause = causes.firstWhere((c) => c.id == _selectedCauseId);
    _activeCause = cause;

    setState(() => _isProcessing = true);

    final user = FirebaseAuth.instance.currentUser;

    await _paymentService.startDonation(
      causeId: cause.id,
      amount: _finalAmount!,
      anonymous: _isAnonymous,
      contactPhone: user?.phoneNumber,
      contactEmail: user?.email,
    );
  }

  void _onPaymentSuccess(String donationId) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ThankYouScreen(
          causeTitle: _activeCause?.title ?? 'Birthday for a Cause',
          amount: _finalAmount ?? 100,
          anonymous: _isAnonymous,
          donationId: donationId,
        ),
      ),
    );
  }

  void _onPaymentError(String message) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment cancelled or failed: $message'),
        backgroundColor: AppColors.error,
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

            // Default to preselected cause if exists
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
                          decoration: InputDecoration(
                            hintText: 'Enter other amount (min ₹100)',
                            errorText: (_customAmountController.text.isNotEmpty &&
                                    (double.tryParse(_customAmountController.text) ?? 0) < 100)
                                ? 'Minimum donation is ₹100'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.gutter),

                // Anonymous Donation Option
                InkWell(
                  onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isAnonymous,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isAnonymous = val ?? false),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Make donation anonymous',
                                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                              ),
                              Text(
                                'Your name will not appear on public donor lists',
                                style: AppTextStyles.bodyMd.copyWith(fontSize: 11.5, color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canContinue ? () => _onProceedToPay(causes) : null,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _finalAmount != null
                                    ? 'Proceed to Pay ₹${_finalAmount!.toInt()}'
                                    : 'Continue to Payment',
                              ),
                              const SizedBox(width: AppSpacing.unit),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
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
                color: cause.badgeColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(cause.icon, color: cause.badgeColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cause.badgeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          cause.tag.toUpperCase(),
                          style: AppTextStyles.labelCaps.copyWith(color: cause.badgeColor, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.unit),
                      Expanded(
                        child: Text(
                          cause.title,
                          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.unit / 2),
                  Text(
                    cause.description ?? '',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _AmountCircle extends StatelessWidget {
  final _AmountOption option;
  final bool selected;
  final VoidCallback onTap;

  const _AmountCircle({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹${option.amount.toInt()}',
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 16,
                color: selected ? AppColors.onPrimaryContainer : AppColors.onSurface,
              ),
            ),
            Text(
              option.label,
              style: AppTextStyles.labelCaps.copyWith(
                fontSize: 9,
                color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
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
