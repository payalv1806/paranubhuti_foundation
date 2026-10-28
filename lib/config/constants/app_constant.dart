import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // App info
  static const String appName = 'Paranubhuti Foundation';
  static const String logoPath = 'assets/images/Ngo_Logo.png';

  // Backend API URL (can be customized at compile-time via --dart-define=BACKEND_URL=...)
  // On web, an empty string uses relative paths (e.g. /api/payment/create-order), avoiding CORS.
  static String get backendBaseUrl {
    const definedUrl = String.fromEnvironment('BACKEND_URL');
    if (definedUrl.isNotEmpty) return definedUrl;
    if (kIsWeb) return ''; // Relative to hosting domain (Netlify)
    return 'https://paranubhutifoundation.netlify.app';
  }

  // Razorpay Public Key ID (Test or Live)
  // Can be passed via --dart-define=RAZORPAY_KEY_ID=rzp_test_... or fetched dynamically from backend
  static const String defaultRazorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_51341144144414',
  );
}
