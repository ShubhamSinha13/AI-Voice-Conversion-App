import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'dart:async';
import '../providers/voice_provider.dart';
import '../providers/auth_provider.dart';

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
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  String? _filePath;
  int _sampleCount = 0;

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
    try {
      if (await _record.hasPermission()) {
        await _record.start();
        setState(() => _isRecording = true);

        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          setState(() {
            _recordDuration += const Duration(milliseconds: 100);
          });
        });
      }
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _record.stop();
      setState(() {
        _isRecording = false;
        _filePath = path;
      });
      _timer?.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording saved: $path')),
      );
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _filePath = result.files.first.path;
          _recordDuration = Duration.zero;
        });
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _uploadVoice() async {
    if (_voiceNameController.text.isEmpty) {
      _showError('Please enter a voice name');
      return;
    }

    if (_filePath == null) {
      _showError('Please record or upload an audio file');
      return;
    }

    final token = ref.read(authTokenProvider);
    if (token == null) {
      _showError('Authentication required');
      return;
    }

    try {
      await ref.read(voiceProvider.notifier).createVoice(
            name: _voiceNameController.text,
            userDefinedName: _voiceNameController.text,
            token: token,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice created successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Failed to create voice: $e');
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
      body: SingleChildScrollView(
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
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _filePath != null ? _uploadVoice : null,
                  child: const Text('Create Voice'),
                ),
              ),
            ],
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
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
