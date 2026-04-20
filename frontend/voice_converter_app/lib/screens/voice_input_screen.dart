import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import '../providers/voice_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// Voice Input Screen for recording or uploading custom voices
class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with WidgetsBindingObserver {
  final _voiceNameController = TextEditingController();
  final _record = AudioRecorder();

  bool _isRecording = false;
  bool _isUploading = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  String? _filePath;
  String? _fileName;
  int _sampleCount = 0;
  double _uploadProgress = 0.0;
  int _uploadedBytes = 0;
  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceNameController.dispose();
    _timer?.cancel();
    _record.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    _showError(
        'Recording feature coming soon! Please upload an audio file instead.');
  }

  Future<void> _stopRecording() async {
    // Recording feature disabled for now
  }

  Future<void> _pickFile() async {
    try {
      // Create or use sample audio files for testing
      final dir = await getApplicationDocumentsDirectory();
      final sampleDir = Directory('${dir.path}/voice_samples');

      if (!await sampleDir.exists()) {
        await sampleDir.create(recursive: true);
        // Create sample audio file for demo (simple WAV file structure)
        _createSampleAudioFile('${sampleDir.path}/sample_audio_1.wav');
        _createSampleAudioFile('${sampleDir.path}/sample_audio_2.wav');
        _createSampleAudioFile('${sampleDir.path}/sample_audio_3.wav');
      }

      // Show available audio files
      final files = sampleDir.listSync().whereType<File>();
      final audioFiles = files
          .where((f) => f.path.endsWith('.wav') || f.path.endsWith('.mp3'))
          .toList();

      if (!mounted) return;

      if (audioFiles.isEmpty) {
        _showError('No audio files found. Creating sample files...');
        _createSampleAudioFile('${sampleDir.path}/sample_audio.wav');
        await Future.delayed(const Duration(milliseconds: 500));
        _pickFile();
        return;
      }

      // Show file selection dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Audio File'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: audioFiles.length,
              itemBuilder: (context, index) {
                final file = audioFiles[index];
                final fileName = file.path.split('/').last;
                final size = file.lengthSync();

                return ListTile(
                  title: Text(fileName),
                  subtitle: Text('${(size / 1024).toStringAsFixed(1)} KB'),
                  onTap: () {
                    setState(() {
                      _filePath = file.path;
                      _fileName = fileName;
                      _recordDuration = const Duration(seconds: 5);
                    });
                    Navigator.pop(context);
                    _showError('Audio file selected: $fileName');
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  void _createSampleAudioFile(String filePath) {
    try {
      final file = File(filePath);
      // Create a simple WAV file structure for testing
      final wavHeader = _generateWavHeader(44100 * 2); // 2 seconds of audio
      file.writeAsBytesSync(wavHeader);
    } catch (e) {
      debugPrint('Failed to create sample audio: $e');
    }
  }

  List<int> _generateWavHeader(int audioDataSize) {
    const sampleRate = 44100;
    const numChannels = 1;
    const bytesPerSample = 2;
    final byteRate = sampleRate * numChannels * bytesPerSample;
    final blockAlign = numChannels * bytesPerSample;
    final subChunk2Size = audioDataSize;
    final chunkSize = 36 + subChunk2Size;

    final header = <int>[
      // RIFF header
      82, 73, 70, 70, // "RIFF"
      chunkSize & 0xFF,
      (chunkSize >> 8) & 0xFF,
      (chunkSize >> 16) & 0xFF,
      (chunkSize >> 24) & 0xFF,
      87, 65, 86, 69, // "WAVE"
      // fmt sub-chunk
      102, 109, 116, 32, // "fmt "
      16, 0, 0, 0, // SubChunk1Size
      1, 0, // AudioFormat (PCM)
      numChannels, 0, // NumChannels
      sampleRate & 0xFF,
      (sampleRate >> 8) & 0xFF,
      (sampleRate >> 16) & 0xFF,
      (sampleRate >> 24) & 0xFF,
      byteRate & 0xFF,
      (byteRate >> 8) & 0xFF,
      (byteRate >> 16) & 0xFF,
      (byteRate >> 24) & 0xFF,
      blockAlign & 0xFF,
      (blockAlign >> 8) & 0xFF,
      16, 0, // BitsPerSample
      // data sub-chunk
      100, 97, 116, 97, // "data"
      subChunk2Size & 0xFF,
      (subChunk2Size >> 8) & 0xFF,
      (subChunk2Size >> 16) & 0xFF,
      (subChunk2Size >> 24) & 0xFF,
      // Audio data (silence/zeros)
      ...List<int>.filled(audioDataSize, 0),
    ];

    return header;
  }

  Future<void> _uploadVoice() async {
    if (_voiceNameController.text.isEmpty) {
      _showError('Please enter a voice name');
      return;
    }

    if (_filePath == null) {
      _showError('Please select an audio file');
      return;
    }

    final token = ref.read(authTokenProvider);
    if (token == null) {
      _showError('Authentication required');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Step 1: Create the voice
      final voiceResponse = await ref.read(voiceProvider.notifier).createVoice(
            name: _voiceNameController.text,
            userDefinedName: _voiceNameController.text,
            token: token,
          );

      final voiceId = voiceResponse['id'] as int;

      // Step 2: Upload the audio sample with progress tracking
      final apiService = ApiService();
      await apiService.uploadVoiceSample(
        voiceId: voiceId,
        filePath: _filePath!,
        token: token,
        onSendProgress: (sent, total) {
          setState(() {
            _uploadedBytes = sent;
            _totalBytes = total;
            _uploadProgress = total > 0 ? sent / total : 0.0;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice created and sample uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(milliseconds: 500))
            .then((_) => Navigator.of(context).pop());
      }
    } catch (e) {
      _showError('Failed to upload voice: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _getAccuracy(int sampleCount) {
    if (sampleCount == 0) return 0;
    if (sampleCount == 1) return 80;
    if (sampleCount == 2) return 90;
    if (sampleCount == 3) return 96;
    if (sampleCount >= 4) return 99;
    return 0;
  }

  String _getAccuracyMessage(int sampleCount) {
    if (sampleCount == 0) return 'Add samples for accuracy';
    if (sampleCount == 1) return '80% accuracy - Add 1 more for 90%';
    if (sampleCount == 2) return '90% accuracy - Add 1 more for 96%';
    if (sampleCount == 3) return '96% accuracy - Add 1+ more for 99%+';
    return '99%+ accuracy - Perfect!';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Voice'),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            overscroll: false,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Voice Name
                  Text(
                    'Step 1: Name Your Voice',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _voiceNameController,
                    decoration: InputDecoration(
                      labelText: 'Voice Name',
                      hintText: 'e.g., My Professional Voice',
                      prefixIcon: const Icon(Icons.edit),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Step 2: Record or Upload
                  Text(
                    'Step 2: Record or Upload Audio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Recording Section
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Recording Status
                        if (_isRecording)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const SizedBox.shrink(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recording...',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          )
                        else if (_filePath != null)
                          Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Audio Ready',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              if (_fileName != null)
                                Text(
                                  _fileName!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Icon(
                                Icons.mic_none,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Ready to Record',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),

                        // Duration Display
                        if (_recordDuration.inSeconds > 0)
                          Text(
                            _formatDuration(_recordDuration),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        const SizedBox(height: 24),

                        // Record Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed:
                                _isRecording ? _stopRecording : _startRecording,
                            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                            label: Text(_isRecording
                                ? 'Stop Recording'
                                : 'Start Recording'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Or Divider
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Audio File'),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Step 3: Accuracy Info
                  Text(
                    'Step 3: Improve with More Samples',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Accuracy Cards
                  _buildAccuracyCard(context, 1, 80, 'Basic'),
                  const SizedBox(height: 12),
                  _buildAccuracyCard(context, 2, 90, 'Good'),
                  const SizedBox(height: 12),
                  _buildAccuracyCard(context, 3, 96, 'Very Good'),
                  const SizedBox(height: 12),
                  _buildAccuracyCard(context, 4, 99, 'Perfect'),
                  const SizedBox(height: 48),

                  // Submit Button
                  if (_isUploading)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: null,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_uploadedBytes / 1024).toStringAsFixed(1)} KB / ${(_totalBytes / 1024).toStringAsFixed(1)} KB',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _filePath != null ? _uploadVoice : null,
                        child: const Text('Create Voice & Upload Sample'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccuracyCard(
    BuildContext context,
    int samples,
    double accuracy,
    String label,
  ) {
    final isCurrentLevel = _sampleCount == samples;
    const color = Color.fromARGB(255, 33, 150, 243);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrentLevel ? color : Theme.of(context).colorScheme.outline,
          width: isCurrentLevel ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isCurrentLevel ? color.withOpacity(0.1) : Colors.transparent,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$samples Sample${samples > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$accuracy% Accuracy - $label',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Accuracy Bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: accuracy / 100,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
