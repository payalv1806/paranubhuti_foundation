import 'package:flutter/material.dart';
import 'package:paranubhutifoundation/config/routes/routes_name.dart';

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
      child: NavigationBar(
        selectedIndex: selectedIndex,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => _navigate(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_rounded),
            label: 'Causes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}