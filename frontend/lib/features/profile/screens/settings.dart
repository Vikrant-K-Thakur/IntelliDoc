// screens/settings.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:docuverse/services/auth_service.dart';
import 'package:docuverse/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  
  bool _notificationsEnabled = true;
  bool _autoSyncEnabled = true;
  bool _offlineMode = false;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Settings
            _buildSectionHeader('Account Settings'),
            const SizedBox(height: 16),
            _buildSettingsItem(
              'Profile Information',
              'Update your personal details',
              Icons.person_outline,
              onTap: () => _showComingSoon('Profile Information'),
            ),
            _buildSettingsItem(
              'Privacy & Security',
              'Manage your privacy settings',
              Icons.security_outlined,
              onTap: () => _showComingSoon('Privacy & Security'),
            ),
            _buildSettingsItem(
              'Account Management',
              'Delete account, export data',
              Icons.manage_accounts_outlined,
              onTap: () => _showComingSoon('Account Management'),
            ),
            
            const SizedBox(height: 30),
            
            // App Preferences
            _buildSectionHeader('App Preferences'),
            const SizedBox(height: 16),
            _buildSwitchItem(
              'Push Notifications',
              'Receive updates and reminders',
              Icons.notifications_outlined,
              _notificationsEnabled,
              (value) => setState(() => _notificationsEnabled = value),
            ),
            _buildDropdownItem(
              'Language',
              'Choose your preferred language',
              Icons.language_outlined,
              _selectedLanguage,
              ['English', 'Spanish', 'French', 'German', 'Chinese'],
              (value) => setState(() => _selectedLanguage = value!),
            ),
            _buildDropdownItem(
              'Theme',
              'Select app appearance',
              Icons.palette_outlined,
              _selectedTheme,
              ['System', 'Light', 'Dark'],
              (value) => setState(() => _selectedTheme = value!),
            ),
            
            const SizedBox(height: 30),
            
            // Document Settings
            _buildSectionHeader('Document Settings'),
            const SizedBox(height: 16),
            _buildSwitchItem(
              'Auto-Sync',
              'Automatically sync documents',
              Icons.sync_outlined,
              _autoSyncEnabled,
              (value) => setState(() => _autoSyncEnabled = value),
            ),
            _buildSwitchItem(
              'Offline Mode',
              'Access documents without internet',
              Icons.offline_bolt_outlined,
              _offlineMode,
              (value) => setState(() => _offlineMode = value),
            ),
            _buildSettingsItem(
              'Storage Management',
              'Manage local storage and cache',
              Icons.storage_outlined,
              onTap: () => _showStorageDialog(),
            ),
            _buildSettingsItem(
              'Default Upload Settings',
              'Set default folder and permissions',
              Icons.upload_outlined,
              onTap: () => _showComingSoon('Default Upload Settings'),
            ),
            
            const SizedBox(height: 30),
            
            // AI & Features
            _buildSectionHeader('AI & Features'),
            const SizedBox(height: 16),
            _buildSettingsItem(
              'AI Preferences',
              'Customize AI behavior and responses',
              Icons.psychology_outlined,
              onTap: () => _showComingSoon('AI Preferences'),
            ),
            _buildSettingsItem(
              'Feature Labs',
              'Try experimental features',
              Icons.science_outlined,
              onTap: () => _showComingSoon('Feature Labs'),
            ),
            
            const SizedBox(height: 30),
            
            // Support & About
            _buildSectionHeader('Support & About'),
            const SizedBox(height: 16),
            _buildSettingsItem(
              'Help Center',
              'Get help and support',
              Icons.help_outline,
              onTap: () => _showComingSoon('Help Center'),
            ),
            _buildSettingsItem(
              'Contact Support',
              'Report issues or get assistance',
              Icons.support_agent_outlined,
              onTap: () => _showComingSoon('Contact Support'),
            ),
            _buildSettingsItem(
              'About DocuVerse',
              'Version info and legal',
              Icons.info_outline,
              onTap: () => _showAboutDialog(),
            ),
            
            const SizedBox(height: 40),
            
            // Danger Zone
            _buildSectionHeader('Danger Zone', color: Colors.red),
            const SizedBox(height: 16),
            _buildSettingsItem(
              'Sign Out',
              'Sign out of your account',
              Icons.logout,
              color: Colors.red,
              onTap: () => _showSignOutDialog(),
            ),
            _buildSettingsItem(
              'Delete Account',
              'Permanently delete your account',
              Icons.delete_forever_outlined,
              color: Colors.red,
              onTap: () => _showDeleteAccountDialog(),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color ?? Colors.black,
      ),
    );
  }

  Widget _buildSettingsItem(
    String title,
    String subtitle,
    IconData icon, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.blue, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        tileColor: Colors.white,
      ),
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        tileColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdownItem(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          underline: const SizedBox(),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        tileColor: Colors.white,
      ),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Storage Usage:'),
            const SizedBox(height: 10),
            _buildStorageItem('Documents', '2.3 GB', 0.6),
            _buildStorageItem('Cache', '450 MB', 0.2),
            _buildStorageItem('Offline Files', '1.1 GB', 0.3),
            const SizedBox(height: 20),
            const Text('Total: 3.85 GB of 15 GB used'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Clear Cache'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String label, String size, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(width: 8),
          Text(size, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About DocuVerse'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: 2024.1.0'),
            SizedBox(height: 16),
            Text('DocuVerse is your AI-powered document management and learning companion.'),
            SizedBox(height: 16),
            Text('© 2024 DocuVerse. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
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
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}