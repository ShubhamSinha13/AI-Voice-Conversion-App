import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    // Load voices on init
    Future.microtask(() {
      ref.read(voiceProvider.notifier).loadPredefinedVoices();
      final token = ref.read(authTokenProvider);
      if (token != null) {
        ref.read(voiceProvider.notifier).loadCustomVoices(token);
      }
    });
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
                      currentUser?.username.substring(0, 1).toUpperCase() ??
                          'U',
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
class PredefinedVoicesTab extends ConsumerWidget {
  const PredefinedVoicesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceProvider);
    final voices = voiceState.predefinedVoices;

    if (voiceState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (voices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No predefined voices available',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: voices.length,
      itemBuilder: (context, index) {
        final voice = voices[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.mic),
            title: Text(voice.name),
            subtitle: Text(voice.category ?? 'Voice'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref.read(voiceProvider.notifier).selectVoice(voice);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected ${voice.name}')),
                    );
                  },
                  child: const Text('Use'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom Voices Tab
class CustomVoicesTab extends ConsumerWidget {
  const CustomVoicesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customVoices = ref.watch(customVoicesProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
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
          ...customVoices.map((voice) {
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
          }).toList(),
      ],
    );
  }
}
