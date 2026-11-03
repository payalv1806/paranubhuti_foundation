import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/features/donation/presentation/screen/donate_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/causes_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/home_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/profile_screen.dart';
//import 'package:paranubhutifoundation/features/home/presentation/screens/splash_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/voulenter.dart';

import 'package:paranubhutifoundation/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:paranubhutifoundation/features/donation/presentation/screen/my_certificates_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/all_fundraisers_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/privacy_security_screen.dart';

class RoutesNames {
  //static const splash = '/';
  static const String homescreen = '/homescreen';
  static const String donate = '/donate';
  static const String volunter = '/volunter';
  static const String causes = '/causes';
  static const String profile = '/profile';
  static const String adminDashboard = '/adminDashboard';
  static const String myCertificates = '/myCertificates';
  static const String allFundraisers = '/allFundraisers';
  static const String privacySecurity = '/privacySecurity';

  static Map<String, WidgetBuilder> get routes => {
    //splash:(_) => SplashScreen(),
    homescreen: (_) => const HomeScreen(),
    donate: (_) => const DonateScreen(),
    volunter: (_) => const VoulenterScreen(),
    causes: (_) => const CausesScreen(),
    profile: (_) => const ProfileScreen(),
    adminDashboard: (_) => const AdminDashboardScreen(),
    myCertificates: (_) => const MyCertificatesScreen(),
    allFundraisers: (_) => const AllFundraisersScreen(),
    privacySecurity: (_) => const PrivacySecurityScreen(),
  };
}
