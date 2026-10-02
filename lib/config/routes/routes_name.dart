import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/features/donation/presentation/screen/donate_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/causes_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/home_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/profile_screen.dart';
//import 'package:paranubhutifoundation/features/home/presentation/screens/splash_screen.dart';
import 'package:paranubhutifoundation/features/home/presentation/screens/voulenter.dart';

class RoutesNames {
  //static const splash = '/';
  static const String homescreen = '/homescreen';
  static const String donate = '/donate';
  static const String volunter = '/volunter';
  static const String causes = '/causes';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
    //splash:(_) => SplashScreen(),
    homescreen: (_) => const HomeScreen(),
    donate: (_) => const DonateScreen(),
    volunter: (_) => const VoulenterScreen(),
    causes: (_) => const CausesScreen(),
    profile: (_) => const ProfileScreen(),
  };
}
