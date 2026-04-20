import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/voice_provider.dart';
import '../services/api_service.dart';
import 'voice_input_screen.dart';
import 'voice_detail_screen.dart';
import 'voice_conversion_screen.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const VoiceConversionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.record_voice_over),
        label: const Text('Convert Voice'),
      ),
    );
  }
}

/// Predefined Voices Tab
class PredefinedVoicesTab extends ConsumerStatefulWidget {
  const PredefinedVoicesTab({Key? key}) : super(key: key);

  @override
  ConsumerState<PredefinedVoicesTab> createState() =>
      _PredefinedVoicesTabState();
}

class _PredefinedVoicesTabState extends ConsumerState<PredefinedVoicesTab> {
  late AudioPlayer _audioPlayer;
  int? _playingVoiceId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playVoicePreview(int voiceId, String voiceName) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // If already playing this voice, stop it
      if (_playingVoiceId == voiceId) {
        await _audioPlayer.stop();
        setState(() {
          _playingVoiceId = null;
          _isLoading = false;
        });
        return;
      }

      final token = ref.read(authTokenProvider);
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
        return;
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/voice_preview_${voiceId}_${DateTime.now().millisecondsSinceEpoch}.mp3';

      // Download preview
      await ApiService().playVoicePreview(
        voiceId: voiceId,
        token: token,
        savePath: filePath,
      );

      // Play audio
      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();

      setState(() {
        _playingVoiceId = voiceId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing preview: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        final isPlaying = _playingVoiceId == voice.id;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text(voice.name),
            subtitle: Text(voice.category ?? 'Voice'),
            trailing: SizedBox(
              width: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Play button
                  IconButton(
                    icon: isPlaying && !_isLoading
                        ? const Icon(Icons.stop, color: Colors.red)
                        : const Icon(Icons.play_arrow, color: Colors.blue),
                    onPressed: _isLoading
                        ? null
                        : () => _playVoicePreview(voice.id, voice.name),
                    tooltip: isPlaying ? 'Stop' : 'Listen',
                  ),
                  // Use button
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
          ),
        );
      },
    );
  }
}

/// Custom Voices Tab
class CustomVoicesTab extends ConsumerStatefulWidget {
  const CustomVoicesTab({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomVoicesTab> createState() => _CustomVoicesTabState();
}

class _CustomVoicesTabState extends ConsumerState<CustomVoicesTab> {
  late AudioPlayer _audioPlayer;
  int? _playingVoiceId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playVoicePreview(int voiceId, String voiceName) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // If already playing this voice, stop it
      if (_playingVoiceId == voiceId) {
        await _audioPlayer.stop();
        setState(() {
          _playingVoiceId = null;
          _isLoading = false;
        });
        return;
      }

      final token = ref.read(authTokenProvider);
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
        return;
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/voice_preview_${voiceId}_${DateTime.now().millisecondsSinceEpoch}.mp3';

      // Download preview
      await ApiService().playVoicePreview(
        voiceId: voiceId,
        token: token,
        savePath: filePath,
      );

      // Play audio
      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();

      setState(() {
        _playingVoiceId = voiceId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing preview: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            final isPlaying = _playingVoiceId == voice.id;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(voice.userDefinedName ?? voice.name),
                subtitle: Text(
                  '$accuracy% • ${voice.sampleCount} sample${voice.sampleCount != 1 ? 's' : ''}',
                ),
                trailing: SizedBox(
                  width: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Play button (only if voice has samples)
                      if (voice.sampleCount > 0)
                        IconButton(
                          icon: isPlaying && !_isLoading
                              ? const Icon(Icons.stop, color: Colors.red)
                              : const Icon(Icons.play_arrow,
                                  color: Colors.blue),
                          onPressed: _isLoading
                              ? null
                              : () => _playVoicePreview(voice.id, voice.name),
                          tooltip: isPlaying ? 'Stop' : 'Listen',
                        )
                      else
                        Tooltip(
                          message: 'Upload samples to listen',
                          child: IconButton(
                            icon: const Icon(Icons.play_arrow,
                                color: Colors.grey),
                            onPressed: null,
                          ),
                        ),
                      // Details button
                      SizedBox(
                        width: 80,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    VoiceDetailScreen(voice: voice),
                              ),
                            );
                          },
                          child: const Text('Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}
