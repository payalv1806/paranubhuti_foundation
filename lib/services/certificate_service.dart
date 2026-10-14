import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:paranubhutifoundation/models/certificate_model.dart';

/// Service responsible for issuing, storing, and generating PDF certificates
/// for verified donations.
class CertificateService {
  static final CertificateService _instance = CertificateService._internal();
  factory CertificateService() => _instance;
  CertificateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches an existing certificate or generates a new one if the donation is verified.
  /// Uses [donationId] as the Firestore document ID to strictly guarantee duplicate prevention.
  Future<CertificateModel?> generateOrGetCertificate(String donationId) async {
    final certDocRef = _firestore.collection('certificates').doc(donationId);
    final existingCert = await certDocRef.get();

    if (existingCert.exists) {
      return CertificateModel.fromMap(existingCert.data()!, existingCert.id);
    }

    // 1. Verify donation existence and status
    final donationDoc = await _firestore.collection('donations').doc(donationId).get();
    if (!donationDoc.exists) {
      throw Exception('Donation record not found.');
    }

    final data = donationDoc.data()!;
    final paymentStatus = data['paymentStatus'] as String?;
    final razorpayPaymentId = data['razorpayPaymentId'] as String?;

    // Strict validation: Only verified successful payments get certificates
    if (paymentStatus != 'completed' || razorpayPaymentId == null || razorpayPaymentId.isEmpty) {
      throw Exception('Cannot issue certificate for an unverified or incomplete transaction.');
    }

    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final isAnonymous = data['anonymous'] as bool? ?? false;
    final userId = data['userId'] as String? ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final causeId = data['causeId'] as String? ?? 'General Cause';

    // 2. Resolve Cause Title
    String causeTitle = 'Birthday for a Cause';
    try {
      final causeDoc = await _firestore.collection('causes').doc(causeId).get();
      if (causeDoc.exists) {
        causeTitle = causeDoc.data()?['title'] as String? ?? causeId;
      } else {
        causeTitle = causeId;
      }
    } catch (_) {
      causeTitle = causeId;
    }

    // 3. Resolve Donor Name
    String donorName = 'Well-Wisher';
    if (isAnonymous) {
      donorName = 'Anonymous Supporter';
    } else {
      try {
        if (userId.isNotEmpty) {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          final uName = userDoc.data()?['name'] as String?;
          if (uName != null && uName.trim().isNotEmpty) {
            donorName = uName.trim();
          } else {
            donorName = FirebaseAuth.instance.currentUser?.displayName ?? 'Valued Supporter';
          }
        }
      } catch (_) {
        donorName = FirebaseAuth.instance.currentUser?.displayName ?? 'Valued Supporter';
      }
    }

    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = donationId.length >= 6 ? donationId.substring(0, 6).toUpperCase() : 'CERT';
    final certId = 'PF-CERT-$dateStr-$suffix';

    final cert = CertificateModel(
      id: certId,
      donationId: donationId,
      userId: userId,
      donorName: donorName,
      amount: amount,
      causeTitle: causeTitle,
      razorpayPaymentId: razorpayPaymentId,
      issuedAt: now,
    );

    await certDocRef.set(cert.toMap());
    return cert;
  }

  /// Streams all certificates issued to a specific user.
  Stream<List<CertificateModel>> getCertificatesStream(String userId) {
    return _firestore
        .collection('certificates')
        .where('userId', isEqualTo: userId)
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificateModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Builds a high-resolution, printable PDF document for the certificate.
  Future<Uint8List> buildPdfBytes(CertificateModel cert) async {
    final pdf = pw.Document();

    // Load foundation logo from assets
    pw.ImageProvider? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/Ngo_Logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    final dateFormatted = _formatDate(cert.issuedAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#6750A4'), width: 3),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#E0B654'), width: 1.5),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Header Row: Logo & Foundation Title
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 44,
                          height: 44,
                          margin: const pw.EdgeInsets.only(right: 12),
                          child: pw.Image(logoImage),
                        ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'PARANUBHUTI FOUNDATION',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#6750A4'),
                              letterSpacing: 1.5,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Seva For Humanity · Registered Public Charitable Trust',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 8),

                  // Title of Certificate
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColor.fromHex('#E0B654'), width: 1.5),
                        top: pw.BorderSide(color: PdfColor.fromHex('#E0B654'), width: 1.5),
                      ),
                    ),
                    child: pw.Text(
                      'CERTIFICATE OF APPRECIATION',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1C1B1F'),
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 8),

                  pw.Text(
                    'This certificate is gratefully presented to',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                  ),

                  pw.SizedBox(height: 4),

                  // Donor Name
                  pw.Text(
                    cert.donorName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#6750A4'),
                      letterSpacing: 1.2,
                    ),
                  ),

                  pw.Container(
                    width: 200,
                    height: 1,
                    color: PdfColor.fromHex('#6750A4'),
                    margin: const pw.EdgeInsets.symmetric(vertical: 4),
                  ),

                  // Wording
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 30),
                    child: pw.Text(
                      'In heartfelt appreciation of your generous gift of Rs. ${cert.amount.toStringAsFixed(0)} towards "${cert.causeTitle}" through the Birthday for a Cause initiative on $dateFormatted.\nYour compassion and benevolence bring real hope, joy, and positive transformation to lives in need.',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 10.5,
                        lineSpacing: 3,
                        color: PdfColors.grey900,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Signatures & Verification Meta Row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Certificate ID & Transaction Info
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Certificate ID: ${cert.id}',
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                          ),
                          pw.Text(
                            'Payment Ref: ${cert.razorpayPaymentId}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            'Date: $dateFormatted',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                        ],
                      ),

                      // Verification Seal
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColor.fromHex('#E0B654'), width: 1),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'VERIFIED GIFT',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#6750A4'),
                              ),
                            ),
                            pw.Text(
                              'Paranubhuti Foundation',
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                      ),

                      // Authorized Signatory
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 140,
                            height: 1,
                            color: PdfColors.grey600,
                            margin: const pw.EdgeInsets.only(bottom: 4),
                          ),
                          pw.Text(
                            cert.signatoryName,
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                          ),
                          pw.Text(
                            cert.signatoryTitle,
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 6),

                  // Statutory Disclaimer
                  pw.Text(
                    '*Note: This is an official token of appreciation for your charitable contribution and does not constitute a tax deduction receipt under Section 80G.',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Downloads or opens print preview for the PDF certificate across Web and Mobile.
  Future<void> downloadOrPrintPdf(CertificateModel cert) async {
    final pdfBytes = await buildPdfBytes(cert);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Paranubhuti_Certificate_${cert.id}.pdf',
    );
  }

  /// Shares certificate details via WhatsApp.
  Future<void> shareOnWhatsApp(CertificateModel cert) async {
    final text = 'I just supported "${cert.causeTitle}" with a gift of Rs. ${cert.amount.toStringAsFixed(0)} through Paranubhuti Foundation – Birthday for a Cause! Join me in making birthdays meaningful.\nCertificate ID: ${cert.id}\nhttps://paranubhutifoundation.org';
    final url = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to web link
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
