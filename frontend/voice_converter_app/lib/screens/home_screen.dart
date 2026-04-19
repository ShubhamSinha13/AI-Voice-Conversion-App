import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voice.dart';
import '../providers/auth_provider.dart';
import '../providers/voice_provider.dart';
import 'voice_input_screen.dart';
import 'voice_detail_screen.dart';
import 'settings_screen.dart';

/// Home screen with two tabs: Predefined Voices and My Custom Voices
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Converter'),
        elevation: 0,
        actions: [
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          // User Profile Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PopupMenuButton(
              position: PopupMenuPosition.under,
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signed in as',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser?.email ?? 'User',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 12),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Center(
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      currentUser?.username.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.mic), text: 'Predefined Voices'),
            Tab(icon: Icon(Icons.person), text: 'Create Your Own'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Predefined Voices Tab
          PredefinedVoicesTab(),
          // Custom Voices Tab
          CustomVoicesTab(),
        ],
      ),
    );
  }
}

/// Predefined Voices Tab
class PredefinedVoicesTab extends StatelessWidget {
  const PredefinedVoicesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Female Voices Section
          _buildVoiceSection(
            context,
            title: 'Female Voices',
            voices: [
              ('Female Voice 1', 'Soft tone', Icons.person),
              ('Female Voice 2', 'Strong tone', Icons.person),
              ('Female Voice 3', 'Young tone', Icons.person),
              ('Female Voice 4', 'Energetic tone', Icons.person),
            ],
          ),
          const SizedBox(height: 24),

          // Men Voices Section
          _buildVoiceSection(
            context,
            title: 'Men Voices',
            voices: [
              ('Men Voice 1', 'Deep tone', Icons.person),
              ('Men Voice 2', 'Smooth tone', Icons.person),
              ('Men Voice 3', 'Young tone', Icons.person),
              ('Men Voice 4', 'Energetic tone', Icons.person),
            ],
          ),
          const SizedBox(height: 24),

          // Special Voices Section
          _buildVoiceSection(
            context,
            title: 'Special Voices',
            voices: [
              ('🤖 Robotic', 'Synthetic sound', Icons.settings),
              ('🤫 Whisper', 'Quiet, breathy', Icons.volume_mute),
              ('🎭 Cartoon', 'Playful, exaggerated', Icons.theaters),
              ('👴 Elder', 'Aged voice quality', Icons.person),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSection(
    BuildContext context, {
    required String title,
    required List<(String, String, IconData)> voices,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: voices.length,
          itemBuilder: (context, index) {
            final (voiceName, description, icon) = voices[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(icon),
                title: Text(voiceName),
                subtitle: Text(description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Playing $voiceName preview')),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Using $voiceName')),
                        );
                      },
                      child: const Text('Use Now'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Custom Voices Tab
class CustomVoicesTab extends ConsumerWidget {
  const CustomVoicesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customVoices = ref.watch(customVoicesProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Voice Section
          Text(
            'Create Your Own Voice',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Create Voice Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VoiceInputScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Voice'),
            ),
          ),

          const SizedBox(height: 32),

          // My Custom Voices Section
          Text(
            'My Custom Voices',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Custom voices list
          if (customVoices.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.mic_none,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No custom voices yet',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first voice to get started',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customVoices.length,
              itemBuilder: (context, index) {
                final voice = customVoices[index];
                final accuracy = voice.accuracyPercentage.toInt();

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.mic,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(voice.userDefinedName ?? voice.name),
                    subtitle: Text(
                      '$accuracy% • ${voice.sampleCount} sample${voice.sampleCount != 1 ? 's' : ''}',
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => VoiceDetailScreen(voice: voice),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
