import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/config/constants/app_constant.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  late Animation<double> _textOpacity;
  late Animation<Offset> _textOffset;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    _logoOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_logoController);

    _textOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_textController);

    _textOffset = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    try {
      if (!mounted) return;
      await _logoController.forward();

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      await _textController.forward();
    } catch (_) {
      // Controller was disposed during navigation/auth state change; safe to ignore
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Widget buildDot(double delay) {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        double value = (_loadingController.value - delay).abs();

        value = value.clamp(0.0, 1.0);

        return Transform.scale(
          scale: 1 + (0.5 * (1 - value)),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.2),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      AppConstants.logoPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(Icons.volunteer_activism_rounded, size: 60, color: Colors.green),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SlideTransition(
              position: _textOffset,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: const [
                    Text(
                      "PARANUBHUTI FOUNDATION",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Together, We Create Change",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildDot(0.0),
                buildDot(0.3),
                buildDot(0.6),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              "Serving Humanity with Compassion",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}