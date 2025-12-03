// screens/personal_space.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:docuverse/shared/widgets/bottom_navigation.dart';
import 'package:docuverse/widgets/app_logo.dart';
import 'edit_profile.dart';
import 'settings.dart';
import 'package:docuverse/services/auth_service.dart';
import 'package:docuverse/services/collaboration_service.dart';
import 'package:docuverse/shared/constants/app_constants.dart';

class PersonalSpaceScreen extends StatefulWidget {
  const PersonalSpaceScreen({super.key});

  @override
  State<PersonalSpaceScreen> createState() => _PersonalSpaceScreenState();
}

class _PersonalSpaceScreenState extends State<PersonalSpaceScreen> {
  final int _currentIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const PersonalSpaceScreenContent(),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        context: context,
      ),
    );
  }
}

class PersonalSpaceScreenContent extends StatefulWidget {
  const PersonalSpaceScreenContent({super.key});

  @override
  State<PersonalSpaceScreenContent> createState() =>
      _PersonalSpaceScreenContentState();
}

class _PersonalSpaceScreenContentState
    extends State<PersonalSpaceScreenContent> {
  User? get currentUser => FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  final CollaborationService _collaborationService = CollaborationService();

  String _getUserInitials(String? displayName) {
    if (displayName == null || displayName.isEmpty) return 'U';

    List<String> nameParts = displayName.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'
          .toUpperCase();
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      await _authService.setLoggedIn(false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 8),

                      // App logo
                      const AppLogo(
                        size: 32,
                        showText: false,
                      ),
                      const SizedBox(width: 12),

                      // Title
                      const Text(
                        'Personal Space',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue,
                          child: Text(
                            _getUserInitials(currentUser?.displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser?.displayName ?? 'User Name',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                currentUser?.email ?? 'user@example.com',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // My Content Section
                    const Text(
                      'My Content',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      'Starred Files',
                      'Your favorite documents',
                      Icons.star_border,
                      Colors.blue,
                      onTap: () =>
                          Navigator.pushNamed(context, '/starred-items'),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      'My Flashcards',
                      'Review and organize your flashcards',
                      Icons.menu_book_outlined,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      'Download Center',
                      'Summaries, translations & quizzes',
                      Icons.download_outlined,
                      Colors.blue,
                    ),
                    const SizedBox(height: 40),

                     // Account Section
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      'Settings',
                      'Manage profile, preferences & more',
                      Icons.settings_outlined,
                      Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      'Collaboration & Sharing',
                      'View and manage shared documents',
                      Icons.people_outline,
                      Colors.blue,
                      onTap: () {
                        Navigator.pushNamed(context, '/collaboration');
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      'Friends',
                      'Manage your friends and chat',
                      Icons.group,
                      Colors.blue,
                      onTap: () {
                        Navigator.pushNamed(context, '/friends');
                      },
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder(
                      stream: _collaborationService.getReceivedFriendRequests(),
                      builder: (context, snapshot) {
                        final requestCount = snapshot.hasData ? snapshot.data!.length : 0;
                        return _buildMenuItemWithBadge(
                          'Notifications',
                          'Friend requests and updates',
                          Icons.notifications_outlined,
                          Colors.blue,
                          badgeCount: requestCount,
                          onTap: () {
                            Navigator.pushNamed(context, '/notifications');
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      'Logout',
                      'Sign out of your account',
                      Icons.logout,
                      Colors.red,
                      onTap: _logout,
                    ),
                    const SizedBox(height: 30),
                    
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemWithBadge(
      String title, String subtitle, IconData icon, Color iconColor,
      {VoidCallback? onTap, int badgeCount = 0}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(icon, size: 24, color: iconColor),
                if (badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      String title, String subtitle, IconData icon, Color iconColor,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
