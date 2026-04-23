import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:file_picker/file_picker.dart';
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
    try {
      final hasPermission = await _record.hasPermission();
      if (!hasPermission) {
        _showError('Microphone permission is required');
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final filePath =
          '${recordingsDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _record.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _recordDuration = Duration(seconds: timer.tick);
        });
      });
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _record.stop();
      _timer?.cancel();

      if (path == null) {
        _showError('Recording failed, please try again');
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        _showError('Recorded file is unavailable, please try again');
        return;
      }

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _filePath = path;
        _fileName = path.split(Platform.pathSeparator).last;
        _sampleCount = 1;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
      _timer?.cancel();
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      final selectedPath = result?.files.single.path;
      if (selectedPath == null) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _filePath = selectedPath;
        _fileName = result!.files.single.name;
        _sampleCount = 1;
      });
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
        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
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
                                decoration: const BoxDecoration(
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
                              const Icon(
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
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
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
        color:
            isCurrentLevel ? color.withValues(alpha: 0.1) : Colors.transparent,
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
                valueColor: const AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
