import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';
import 'package:paranubhutifoundation/core/theme/app_text_styles.dart';
import 'package:paranubhutifoundation/core/theme/app_theme.dart';
import 'package:paranubhutifoundation/services/payment_service.dart';
import 'thank_you_screen.dart';

/// Payment Details screen — shown after Donate screen, before the actual
/// payment gateway hand-off.
///
/// Note: since this uses Razorpay's native in-app checkout (not a hosted
/// payment link), Razorpay itself shows its own UPI/card/wallet picker once
/// checkout opens. The UPI app grid below is kept for visual familiarity,
/// but tapping a tile doesn't change which app actually opens — that
/// choice happens inside Razorpay's own UI. The UPI ID field, if filled,
/// IS functional — it prefills Razorpay's UPI flow so the donor doesn't
/// have to retype it.
class PaymentDetailsScreen extends StatefulWidget {
  final String causeId;
  final String causeCategory; // e.g. "Selected Cause" label above the title
  final String causeTitle; // e.g. "Food Assistance"
  final double amount;

  const PaymentDetailsScreen({
    super.key,
    required this.causeId,
    required this.causeCategory,
    required this.causeTitle,
    required this.amount,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  static const List<_UpiApp> _upiApps = [
    _UpiApp(name: 'Google Pay', icon: Icons.account_balance_wallet_rounded),
    _UpiApp(name: 'PhonePe', icon: Icons.smartphone_rounded),
    _UpiApp(name: 'Paytm', icon: Icons.qr_code_rounded),
    _UpiApp(name: 'BHIM', icon: Icons.account_balance_rounded),
  ];

  final TextEditingController _upiIdController = TextEditingController();
  String? _selectedApp;
  bool _isAnonymous = false;
  bool _isProcessing = false;
  String? _errorMessage;

  late final PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService()
      ..onSuccess = _onPaymentSuccess
      ..onError = _onPaymentError;
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;

    await _paymentService.startDonation(
      causeId: widget.causeId,
      amount: widget.amount,
      anonymous: _isAnonymous,
      contactPhone: user?.phoneNumber,
      contactEmail: user?.email,
      vpa: _upiIdController.text.trim().isEmpty ? null : _upiIdController.text.trim(),
    );
    // Loading state is cleared in _onPaymentSuccess/_onPaymentError, since
    // Razorpay's checkout is a separate native UI — this call returns as
    // soon as checkout *opens*, not when the payment actually finishes.
  }

  void _onPaymentSuccess(String donationId) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ThankYouScreen(
          causeTitle: widget.causeTitle,
          amount: widget.amount,
          anonymous: _isAnonymous,
        ),
      ),
    );
  }

  void _onPaymentError(String message) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _errorMessage = message;
    });
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
        title: Text('Payment Details', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.unit * 2,
          ),
          children: [
            _SelectedCauseCard(
              causeCategory: widget.causeCategory,
              causeTitle: widget.causeTitle,
              amount: widget.amount,
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter + AppSpacing.unit),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POPULAR UPI APPS',
                      style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _upiApps.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.gutter,
                        mainAxisSpacing: AppSpacing.gutter,
                        childAspectRatio: 2.4,
                      ),
                      itemBuilder: (context, index) {
                        final app = _upiApps[index];
                        return _UpiAppTile(
                          app: app,
                          selected: _selectedApp == app.name,
                          onTap: () => setState(() => _selectedApp = app.name),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),

                    Text(
                      'OR ENTER UPI ID',
                      style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.unit),
                    TextField(
                      controller: _upiIdController,
                      decoration: const InputDecoration(
                        hintText: 'username@bank',
                        suffixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap - AppSpacing.unit),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.secondaryContainer,
                          child: Icon(
                            _isAnonymous ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 18,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gutter),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Anonymous donation', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                'Hide your name from the public list',
                                style: AppTextStyles.bodyMd.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAnonymous,
                          activeThumbColor: AppColors.primary,
                          onChanged: (value) => setState(() => _isAnonymous = value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.gutter),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: AppSpacing.sectionGap),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _onConfirm,
                child: _isProcessing
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock_rounded, size: 18),
                    SizedBox(width: AppSpacing.unit),
                    Text('Confirm & Donate'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('SSL ENCRYPTED', style: AppTextStyles.labelCaps.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
                    const SizedBox(width: AppSpacing.gutter),
                    Icon(Icons.verified_user_outlined, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('SECURE PAYMENT', style: AppTextStyles.labelCaps.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  'Your contribution goes directly to the selected cause. We use industry-standard encryption to protect your sensitive information.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedCauseCard extends StatelessWidget {
  final String causeCategory;
  final String causeTitle;
  final double amount;

  const _SelectedCauseCard({
    required this.causeCategory,
    required this.causeTitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter + AppSpacing.unit),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        causeCategory.toUpperCase(),
                        style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        causeTitle,
                        style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL GIFT',
                      style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '80G Tax Exemption eligible · 100% reaches the cause',
                      style: AppTextStyles.bodyMd.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpiApp {
  final String name;
  final IconData icon;
  const _UpiApp({required this.name, required this.icon});
}

class _UpiAppTile extends StatelessWidget {
  final _UpiApp app;
  final bool selected;
  final VoidCallback onTap;

  const _UpiAppTile({required this.app, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.unit),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: selected ? AppColors.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(app.icon, size: 20, color: AppColors.onSurface),
            const SizedBox(width: AppSpacing.unit),
            Flexible(
              child: Text(
                app.name,
                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}