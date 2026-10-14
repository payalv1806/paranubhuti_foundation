import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a verified Donation Certificate issued by Paranubhuti Foundation.
class CertificateModel {
  final String id;
  final String donationId;
  final String userId;
  final String donorName;
  final double amount;
  final String causeTitle;
  final String razorpayPaymentId;
  final DateTime issuedAt;
  final String signatoryName;
  final String signatoryTitle;
  final String foundationName;
  final String foundationTagline;

  const CertificateModel({
    required this.id,
    required this.donationId,
    required this.userId,
    required this.donorName,
    required this.amount,
    required this.causeTitle,
    required this.razorpayPaymentId,
    required this.issuedAt,
    this.signatoryName = 'Trustee / Foundation Representative',
    this.signatoryTitle = 'Authorized Signatory',
    this.foundationName = 'Paranubhuti Foundation',
    this.foundationTagline = 'Seva For Humanity',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donationId': donationId,
      'userId': userId,
      'donorName': donorName,
      'amount': amount,
      'causeTitle': causeTitle,
      'razorpayPaymentId': razorpayPaymentId,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'signatoryName': signatoryName,
      'signatoryTitle': signatoryTitle,
      'foundationName': foundationName,
      'foundationTagline': foundationTagline,
    };
  }

  factory CertificateModel.fromMap(Map<String, dynamic> map, String docId) {
    return CertificateModel(
      id: docId,
      donationId: map['donationId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      donorName: map['donorName'] as String? ?? 'Valued Supporter',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      causeTitle: map['causeTitle'] as String? ?? 'Birthday for a Cause',
      razorpayPaymentId: map['razorpayPaymentId'] as String? ?? 'Verified',
      issuedAt: (map['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      signatoryName: map['signatoryName'] as String? ?? 'Trustee / Foundation Representative',
      signatoryTitle: map['signatoryTitle'] as String? ?? 'Authorized Signatory',
      foundationName: map['foundationName'] as String? ?? 'Paranubhuti Foundation',
      foundationTagline: map['foundationTagline'] as String? ?? 'Seva For Humanity',
    );
  }
}
