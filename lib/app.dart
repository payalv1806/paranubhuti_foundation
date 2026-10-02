import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/config/routes/routes_name.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          AppTheme.lightTheme.textTheme,
        ),
      ),
      initialRoute: RoutesNames.homescreen,
      routes: RoutesNames.routes,
    );
  }
}
