import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
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
        children: const [
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
  String _inputMode = 'text'; // 'text' or 'audio'
  String? _selectedAudioPath;
  int? _selectedVoiceForConversion;
  String _qualityLevel = 'basic';

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.processingStateStream.listen((state) {
      if (!mounted) return;
      if (state == ProcessingState.completed) {
        setState(() {
          _playingVoiceId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final pickedPath = result.files.single.path!;
        final sourceFile = File(pickedPath);
        if (!await sourceFile.exists()) {
          throw Exception('Selected file no longer exists');
        }

        // Persist selected audio inside app storage so temp picker cache cleanup
        // does not break conversion requests.
        final appDir = await getApplicationDocumentsDirectory();
        final selectedDir = Directory('${appDir.path}/selected_audio');
        if (!await selectedDir.exists()) {
          await selectedDir.create(recursive: true);
        }
        final originalName = result.files.single.name;
        final ext = originalName.contains('.')
            ? '.${originalName.split('.').last}'
            : '.audio';
        final persistedPath =
            '${selectedDir.path}/input_${DateTime.now().millisecondsSinceEpoch}$ext';
        await sourceFile.copy(persistedPath);

        setState(() {
          _selectedAudioPath = persistedPath;
          _selectedVoiceForConversion = null;
        });
      }
    } catch (e) {
      _showSnack('Error picking file: ${e.toString()}', isError: true);
    }
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
        setState(() {
          _isLoading = false;
        });
        _showSnack('Not authenticated', isError: true);
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
      _showSnack('Error playing preview: ${e.toString()}', isError: true);
    }
  }

  Future<void> _convertAudio(int voiceId, String voiceName) async {
    if (_selectedAudioPath == null) {
      _showSnack('Please select an audio file first', isError: true);
      return;
    }
    if (!File(_selectedAudioPath!).existsSync()) {
      _showSnack('Selected file expired. Please choose again.', isError: true);
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final token = ref.read(authTokenProvider);
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        _showSnack('Not authenticated', isError: true);
        return;
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/voice_converted_${voiceId}_${DateTime.now().millisecondsSinceEpoch}.wav';

      final apiService = ApiService();

      // Call appropriate conversion endpoint based on quality level
      if (_qualityLevel == 'ml') {
        await apiService.convertAudioFileML(
          voiceId: voiceId,
          audioFilePath: _selectedAudioPath!,
          token: token,
          savePath: filePath,
        );
      } else if (_qualityLevel == 'rvc') {
        await apiService.convertAudioFileRVC(
          voiceId: voiceId,
          audioFilePath: _selectedAudioPath!,
          token: token,
          savePath: filePath,
          quality: 'balanced',
        );
      } else {
        // basic quality (default)
        await apiService.convertAudioFile(
          voiceId: voiceId,
          audioFilePath: _selectedAudioPath!,
          token: token,
          savePath: filePath,
        );
      }

      // Play converted audio
      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();

      setState(() {
        _playingVoiceId = voiceId;
        _selectedVoiceForConversion = voiceId;
        _isLoading = false;
      });

      String qualityText = _qualityLevel == 'ml'
          ? 'ML-Enhanced'
          : _qualityLevel == 'rvc'
              ? 'Advanced RVC'
              : 'Basic';
      _showSnack('Converted to $voiceName ($qualityText)');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnack('Error converting audio: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);
    final voices = voiceState.predefinedVoices;

    if (voiceState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (voiceState.error != null && voices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'Could not load voices',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                voiceState.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  ref.read(voiceProvider.notifier).clearError();
                  ref.read(voiceProvider.notifier).loadPredefinedVoices();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Input Mode Toggle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'text',
                          label: Text('Text'),
                          icon: Icon(Icons.text_fields),
                        ),
                        ButtonSegment(
                          value: 'audio',
                          label: Text('Audio File'),
                          icon: Icon(Icons.audio_file),
                        ),
                      ],
                      selected: {_inputMode},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _inputMode = newSelection.first;
                          _selectedAudioPath = null;
                          _selectedVoiceForConversion = null;
                          _playingVoiceId = null;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Audio file selection section
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _inputMode == 'audio'
              ? Padding(
                  key: const ValueKey('audio-mode-panel'),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Convert an Audio File',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickAudioFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Choose Audio File'),
                      ),
                      if (_selectedAudioPath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.audio_file, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedAudioPath!.split('/').last,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Quality',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SegmentedButton<String>(
                                      segments: const [
                                        ButtonSegment(
                                          value: 'basic',
                                          label: Text('Fast'),
                                          icon: Icon(Icons.speed),
                                        ),
                                        ButtonSegment(
                                          value: 'ml',
                                          label: Text('ML'),
                                          icon: Icon(Icons.auto_awesome),
                                        ),
                                        ButtonSegment(
                                          value: 'rvc',
                                          label: Text('RVC'),
                                          icon: Icon(Icons.psychology),
                                        ),
                                      ],
                                      selected: {_qualityLevel},
                                      onSelectionChanged:
                                          (Set<String> newSelection) {
                                        setState(() {
                                          _qualityLevel = newSelection.first;
                                        });
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _qualityLevel == 'basic'
                                      ? 'Fastest conversion with light processing'
                                      : _qualityLevel == 'ml'
                                          ? 'Balanced quality with ML enhancement'
                                          : 'Most detailed conversion (slower)',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Select a target voice below',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('text-mode-panel')),
        ),
        // Voices list
        Expanded(
          child: _buildVoicesList(voices),
        ),
      ],
    );
  }

  Widget _buildVoicesList(List<dynamic> voices) {
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
        final isSelected = _selectedVoiceForConversion == voice.id;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: isSelected
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.35)
              : null,
          child: ListTile(
            onTap: _inputMode == 'text'
                ? () {
                    ref.read(voiceProvider.notifier).selectVoice(voice);
                    _showSnack('Selected ${voice.name}');
                  }
                : null,
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text(
              voice.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(voice.category ?? 'Voice'),
            trailing: _inputMode == 'text'
                ? IconButton(
                    icon: isPlaying && !_isLoading
                        ? const Icon(Icons.stop, color: Colors.red)
                        : const Icon(Icons.play_arrow, color: Colors.blue),
                    onPressed: _isLoading
                        ? null
                        : () => _playVoicePreview(voice.id, voice.name),
                    tooltip: isPlaying ? 'Stop' : 'Listen',
                  )
                : (_selectedAudioPath != null
                    ? SizedBox(
                        width: 80,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _convertAudio(voice.id, voice.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          child: _isLoading && isSelected
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Convert'),
                        ),
                      )
                    : null),
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

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.processingStateStream.listen((state) {
      if (!mounted) return;
      if (state == ProcessingState.completed) {
        setState(() {
          _playingVoiceId = null;
        });
      }
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
        setState(() {
          _isLoading = false;
        });
        _showSnack('Not authenticated', isError: true);
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
      _showSnack('Error playing preview: ${e.toString()}', isError: true);
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
                  width: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
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
                        const Tooltip(
                          message: 'Upload samples to listen',
                          child: IconButton(
                            icon: Icon(Icons.play_arrow, color: Colors.grey),
                            onPressed: null,
                          ),
                        ),
                      // Details button
                      Flexible(
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
