import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/config/routes/routes_name.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';

/// Bottom navigation — 3 tabs: Home, Causes, Profile.
/// Uses your existing named routes (RoutesNames) — these now work because
/// RoutesNames.routes is registered in MaterialApp (main.dart).
class BottomNavigationScreen extends StatelessWidget {
  final int selectedIndex;
  const BottomNavigationScreen({super.key, required this.selectedIndex});

  void _navigate(BuildContext context, int index) {
    if (index == selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, RoutesNames.homescreen);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, RoutesNames.causes);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, RoutesNames.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          height: 72,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.primaryFixed,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => _navigate(context, index),
          destinations: [
            _buildDestination(Icons.home_outlined, Icons.home_filled, 'Home', 0),
            _buildDestination(Icons.favorite_outline_rounded, Icons.favorite_rounded, 'Causes', 1),
            _buildDestination(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 2),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildDestination(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    return NavigationDestination(
      icon: Icon(
        outlinedIcon,
        color: AppColors.onSurfaceVariant,
      ),
      selectedIcon: Icon(
        filledIcon,
        color: AppColors.primary,
      ),
      label: label,
    );
  }
}