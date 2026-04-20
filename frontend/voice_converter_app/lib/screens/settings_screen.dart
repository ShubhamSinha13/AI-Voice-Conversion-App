import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings Screen - User preferences and configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedQuality = 'High';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Settings Section
            _buildSectionHeader(context, 'App Settings'),
            _buildSettingsTile(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Get alerts about voice accuracy',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.brightness_4_outlined,
              title: 'Dark Mode',
              subtitle: 'Use dark theme (system default)',
              trailing: Switch(
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() => _darkModeEnabled = value);
                },
              ),
            ),

            // Audio Settings Section
            const Divider(),
            _buildSectionHeader(context, 'Audio Settings'),
            _buildSettingsTile(
              context,
              icon: Icons.music_note_outlined,
              title: 'Audio Quality',
              subtitle: 'Recording quality: $_selectedQuality',
              onTap: () {
                _showQualityDialog();
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.speed_outlined,
              title: 'Recording Speed',
              subtitle: 'Standard 44.1kHz sampling rate',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recording at 44.1kHz')),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.tune_outlined,
              title: 'Audio Processing',
              subtitle: 'Automatic noise reduction',
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),

            // Voice Settings Section
            const Divider(),
            _buildSectionHeader(context, 'Voice Settings'),
            _buildSettingsTile(
              context,
              icon: Icons.sports_score,
              title: 'Target Accuracy',
              subtitle: 'Aim for 99%+ accuracy',
              onTap: () {},
            ),
            _buildSettingsTile(
              context,
              icon: Icons.storage_outlined,
              title: 'Voice Storage',
              subtitle: 'Voices stored locally & in cloud',
              onTap: () {
                _showStorageInfo();
              },
            ),

            // Privacy & Account Section
            const Divider(),
            _buildSectionHeader(context, 'Privacy & Account'),
            _buildSettingsTile(
              context,
              icon: Icons.lock_outlined,
              title: 'Privacy Policy',
              subtitle: 'Learn about data privacy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening privacy policy...'),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Review terms and conditions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening terms of service...'),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              onTap: () {
                _showDeleteAccountDialog();
              },
            ),

            // App Info Section
            const Divider(),
            _buildSectionHeader(context, 'About'),
            _buildSettingsTile(
              context,
              icon: Icons.info_outlined,
              title: 'App Version',
              subtitle: 'v0.1.0 (Development)',
              onTap: () {},
            ),
            _buildSettingsTile(
              context,
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Help us improve the app',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feedback form opening...'),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  void _showQualityDialog() {
    final qualities = ['Standard', 'High', 'Ultra'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recording Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: qualities.map((quality) {
            return RadioListTile<String>(
              title: Text(quality),
              value: quality,
              groupValue: _selectedQuality,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedQuality = value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Storage'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your custom voices are:'),
            SizedBox(height: 12),
            BulletPoint(text: 'Stored locally on your device'),
            BulletPoint(text: 'Backed up to cloud (encrypted)'),
            BulletPoint(text: 'Synced across your devices'),
            SizedBox(height: 12),
            Text(
              'You have full control over your voice data and can delete any voice at any time.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'Deleting your account will:\n\n'
          '• Remove all custom voices\n'
          '• Delete all app settings\n'
          '• Cannot be undone\n\n'
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion initiated...'),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for bullet points
class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
