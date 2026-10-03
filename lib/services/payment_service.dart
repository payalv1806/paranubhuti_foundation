import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Wraps the Razorpay checkout flow and the Firestore side-effects of a
/// donation: writes a `donations/{id}` doc as `pending` before opening
/// checkout, then updates it to `completed`/`failed` based on the result —
/// and on success, atomically increments `causes/{causeId}.totalRaised`
/// via a transaction so the two numbers can't drift out of sync.
///
/// ⚠️ Test-mode only by default (see [razorpayKeyId]) — swap in your Live
/// key only after testing is complete (Razorpay dashboard → Live Mode).
class PaymentService {
  // 👉 Replace with your Razorpay Test/Live Key ID (Dashboard → API Keys).
  static const String razorpayKeyId = 'rzp_live_dxVrrau5F2oLZR';

  final Razorpay _razorpay = Razorpay();
  String? _pendingDonationId;

  void Function(String donationId)? onSuccess;
  void Function(String message)? onError;

  PaymentService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() => _razorpay.clear();

  /// Creates the `pending` donation doc, then opens Razorpay checkout.
  Future<void> startDonation({
    required String causeId,
    required double amount,
    required bool anonymous,
    String? contactPhone,
    String? contactEmail,
    String? vpa, // UPI ID, if the donor typed one in — prefills Razorpay's UPI flow
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final docRef = await FirebaseFirestore.instance.collection('donations').add({
      'userId': anonymous ? null : uid,
      'causeId': causeId,
      'amount': amount,
      'anonymous': anonymous,
      'paymentStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _pendingDonationId = docRef.id;

    final options = {
      'key': razorpayKeyId,
      'amount': (amount * 100).round(), // Razorpay expects paise, not rupees
      'currency': 'INR',
      'name': 'Birthday for cause',
      'description': 'Donation to $causeId',
      'prefill': {
        if (contactPhone != null && contactPhone.isNotEmpty) 'contact': contactPhone,
        if (contactEmail != null && contactEmail.isNotEmpty) 'email': contactEmail,
        if (vpa != null && vpa.isNotEmpty) 'vpa': vpa,
      },
      // Lets us match the webhook/checkout result back to this donation doc.
      'notes': {'donationId': docRef.id, 'causeId': causeId},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      await docRef.update({'paymentStatus': 'failed'});
      onError?.call('Could not open payment screen. Please try again.');
    }
  }

  Future<void> _handleSuccess(PaymentSuccessResponse response) async {
    final donationId = _pendingDonationId;
    if (donationId == null) return;

    try {
      final donationRef = FirebaseFirestore.instance.collection('donations').doc(donationId);
      final donationSnap = await donationRef.get();
      final causeId = donationSnap.data()?['causeId'] as String?;
      final amount = (donationSnap.data()?['amount'] as num?)?.toDouble() ?? 0;

      if (causeId != null) {
        // Transaction keeps the donation status and the cause's running
        // total in sync — if either write fails, both are rolled back,
        // so totalRaised can never count a donation that didn't actually
        // get marked completed (or vice versa).
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final causeRef = FirebaseFirestore.instance.collection('causes').doc(causeId);
          tx.update(donationRef, {
            'paymentStatus': 'completed',
            'razorpayPaymentId': response.paymentId,
          });
          tx.update(causeRef, {'totalRaised': FieldValue.increment(amount)});
        });
      } else {
        await donationRef.update({
          'paymentStatus': 'completed',
          'razorpayPaymentId': response.paymentId,
        });
      }

      onSuccess?.call(donationId);
    } catch (e) {
      onError?.call('Payment succeeded but we could not record it. Please contact support with payment ID: ${response.paymentId}');
    } finally {
      _pendingDonationId = null;
    }
  }

  Future<void> _handleError(PaymentFailureResponse response) async {
    final donationId = _pendingDonationId;
    if (donationId != null) {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({'paymentStatus': 'failed'});
    }
    _pendingDonationId = null;
    onError?.call(response.message ?? 'Payment failed. Please try again.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // User picked a wallet app (Paytm, etc.) instead of completing in-checkout.
    // No donation status change here — EVENT_PAYMENT_SUCCESS/ERROR will still
    // fire once that flow resolves.
  }
}