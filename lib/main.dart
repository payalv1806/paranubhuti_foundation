import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'authentication/login_screen.dart';
import '/features/home/presentation/screens/home_screen.dart';
import '/features/home/presentation/screens/splash_screen.dart';
import '/config/routes/routes_name.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // If testing against the Firebase Local Emulator, uncomment these two lines:
  // FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

  runApp( const BirthdayForACauseApp());
}

class BirthdayForACauseApp extends StatelessWidget {
  const BirthdayForACauseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birthday for cause',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(AppTheme.lightTheme.textTheme),
      ),
      routes: RoutesNames.routes,

      // 👇 Shows your Splash screen first, then decides Login vs Home.
      home: const AuthGate(),
    );
  }
}

/// Shows SplashScreen for a minimum amount of time (so it's never just a
/// flash, even if Firebase's auth check finishes instantly), THEN checks
/// whether someone's already signed in and routes to Login or Home.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _runSplashDelay();
  }

  Future<void> _runSplashDelay() async {
    // Minimum splash duration — tweak this to whatever feels right (in ms).
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase is still checking its cached session — keep showing
        // Splash a little longer rather than a bare loading spinner.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}