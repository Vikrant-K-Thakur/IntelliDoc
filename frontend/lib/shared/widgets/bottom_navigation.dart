// widgets/bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:docuverse/services/auth_service.dart';
import 'package:docuverse/shared/constants/app_constants.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final BuildContext context;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.context,
  });

  void _checkAuthAndNavigate(String route) {
    if (!AuthService.isLoggedIn) {
      _showLoginDialog();
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login first to preview the app.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            if (currentIndex != 0) _checkAuthAndNavigate(AppConstants.homeRoute);
            break;
          case 1:
            if (currentIndex != 1) _checkAuthAndNavigate(AppConstants.documentsRoute);
            break;
          case 2:
            if (currentIndex != 2) _checkAuthAndNavigate(AppConstants.studyToolsRoute);
            break;
          case 3:
            if (currentIndex != 3) _checkAuthAndNavigate(AppConstants.personalSpaceRoute);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: 'Documents',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Study Tools',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Personal Space',
        ),
      ],
    );
  }
}