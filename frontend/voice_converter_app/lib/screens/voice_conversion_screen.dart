import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import '../providers/voice_provider.dart';
import '../providers/auth_provider.dart';
import '../models/voice.dart';
import '../services/api_service.dart';

class VoiceConversionScreen extends ConsumerStatefulWidget {
  const VoiceConversionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceConversionScreen> createState() =>
      _VoiceConversionScreenState();
}

class _VoiceConversionScreenState extends ConsumerState<VoiceConversionScreen> {
  late TextEditingController _textController;
  late AudioPlayer _audioPlayer;
  late ApiService _apiService;

  int? _selectedVoiceId;
  bool _isConverting = false;
  bool _isPlaying = false;
  String? _currentAudioPath;
  double _playbackProgress = 0.0;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _audioPlayer = AudioPlayer();
    _apiService = ApiService();

    // Listen to playback position for progress bar
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _playbackProgress = _audioPlayer.duration != null
              ? (position.inMilliseconds /
                      _audioPlayer.duration!.inMilliseconds)
                  .clamp(0.0, 1.0)
              : 0.0;
        });
      }
    });

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _convertVoice() async {
    // Validate input
    if (_textController.text.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Please enter text to convert';
          _successMessage = '';
        });
      }
      return;
    }

    if (_selectedVoiceId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Please select a voice';
          _successMessage = '';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isConverting = true;
        _errorMessage = '';
        _successMessage = '';
      });
    }

    try {
      // Get token from auth provider
      final token = ref.read(authTokenProvider);

      if (token == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Not authenticated. Please login again.';
            _isConverting = false;
          });
        }
        return;
      }

      // Call conversion API
      final result = await _apiService.convertVoice(
        text: _textController.text,
        voiceId: _selectedVoiceId!,
        token: token,
      );

      if (result['success'] == true) {
        // Download audio file
        final audioUrl = result['audio_url'];
        final voiceName = result['voice_name'];

        // Get app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final audioDir = '${appDir.path}/voice_conversions';
        final dir = Directory(audioDir);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }

        final fileName =
            '${voiceName}_${DateTime.now().millisecondsSinceEpoch}.wav';
        final savePath = '$audioDir/$fileName';

        // Download audio
        await _apiService.downloadAudio(
          audioUrl: audioUrl,
          savePath: savePath,
          token: token,
        );

        if (mounted) {
          setState(() {
            _currentAudioPath = savePath;
            _successMessage =
                'Voice conversion successful! Duration: ${result['duration_seconds']}s';
            _isConverting = false;
          });
        }

        // Auto-play the audio
        await _playAudio(savePath);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Conversion failed';
            _isConverting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isConverting = false;
        });
      }
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error playing audio: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> _resumeAudio() async {
    await _audioPlayer.play();
  }

  List<DropdownMenuItem<int>> _buildVoiceDropdownItems(
      Map<String, dynamic> allVoices) {
    final voices = [
      ...allVoices['predefined_voices'] ?? [],
      ...allVoices['custom_voices'] ?? [],
    ];

    return voices.map<DropdownMenuItem<int>>((dynamic voice) {
      final voiceObj = voice is Voice ? voice : Voice.fromJson(voice);
      return DropdownMenuItem<int>(
        value: voiceObj.id,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(
                voiceObj.isPredefined ? Icons.star : Icons.person,
                size: 18,
                color: voiceObj.isPredefined ? Colors.amber : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(voiceObj.name),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);
    final allVoices = {
      'predefined_voices': voiceState.predefinedVoices,
      'custom_voices': voiceState.customVoices,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Conversion'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Input Section
            const SizedBox(height: 16),
            const Text(
              'Enter Text to Convert',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type the text you want to convert to speech...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Character count: ${_textController.text.length}/1000',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            // Voice Selection Section
            const SizedBox(height: 24),
            const Text(
              'Select Voice',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                isExpanded: true,
                value: _selectedVoiceId,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const Text('Choose a voice...'),
                ),
                items: _buildVoiceDropdownItems(allVoices),
                onChanged: (value) {
                  setState(() {
                    _selectedVoiceId = value;
                  });
                },
              ),
            ),

            // Error/Success Messages
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),

            // Convert Button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isConverting ? null : _convertVoice,
                child: _isConverting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Converting...'),
                        ],
                      )
                    : const Text('Convert Voice'),
              ),
            ),

            // Audio Player Section
            const SizedBox(height: 32),
            if (_currentAudioPath != null) ...[
              const Text(
                'Playback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    // Progress bar
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        value: _playbackProgress,
                        onChanged: (value) async {
                          if (_audioPlayer.duration != null) {
                            final position = Duration(
                              milliseconds: (value *
                                      _audioPlayer.duration!.inMilliseconds)
                                  .toInt(),
                            );
                            await _audioPlayer.seek(position);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Play/Pause button
                        FloatingActionButton.small(
                          onPressed: _isPlaying ? _pauseAudio : _resumeAudio,
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                        ),

                        // Time display
                        StreamBuilder<Duration?>(
                          stream: _audioPlayer.durationStream,
                          builder: (context, snapshot) {
                            final totalDuration =
                                snapshot.data ?? Duration.zero;
                            final position = Duration(
                              milliseconds: (_playbackProgress *
                                      totalDuration.inMilliseconds)
                                  .toInt(),
                            );
                            return Text(
                              '${_formatDuration(position)} / ${_formatDuration(totalDuration)}',
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),

                        // Stop button
                        FloatingActionButton.small(
                          onPressed: () async {
                            await _audioPlayer.stop();
                            setState(() {
                              _playbackProgress = 0.0;
                            });
                          },
                          child: const Icon(Icons.stop),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
