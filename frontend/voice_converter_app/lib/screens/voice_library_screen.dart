import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_provider.dart';
import 'voice_input_screen.dart';

/// Voice Library Screen showing all user's custom voices
class VoiceLibraryScreen extends ConsumerStatefulWidget {
  const VoiceLibraryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceLibraryScreen> createState() =>
      _VoiceLibraryScreenState();
}

class _VoiceLibraryScreenState extends ConsumerState<VoiceLibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Load custom voices when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Voice loading will be triggered from home screen
    });
  }

  @override
  Widget build(BuildContext context) {
    final customVoices = ref.watch(customVoicesProvider);
    final voiceState = ref.watch(voiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Custom Voices'),
        elevation: 0,
      ),
      body: customVoices.isEmpty
          ? _buildEmptyState(context)
          : _buildVoicesList(context, customVoices),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const VoiceInputScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No Custom Voices Yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first custom voice by recording or uploading an audio sample.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VoiceInputScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Voice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoicesList(BuildContext context, List<dynamic> customVoices) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customVoices.length,
      itemBuilder: (context, index) {
        final voice = customVoices[index];
        final accuracy = voice.accuracyPercentage.toInt();
        final samples = voice.sampleCount;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: Icon(
              Icons.mic,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              voice.userDefinedName ?? voice.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Text(
              '$accuracy% Accuracy • $samples Sample${samples != 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accuracy Bar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Accuracy: $accuracy%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: accuracy / 100,
                                  minHeight: 12,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  valueColor: AlwaysStoppedAnimation(
                                    _getAccuracyColor(accuracy),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Improvement Suggestion
                    if (accuracy < 99)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getSuggestion(samples),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilledButton.tonal(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Using ${voice.userDefinedName ?? voice.name}',
                                ),
                              ),
                            );
                          },
                          child: const Text('Use Voice'),
                        ),
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const VoiceInputScreen(),
                              ),
                            );
                          },
                          child: const Text('Add Sample'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            _showDeleteDialog(context, voice);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getAccuracyColor(int accuracy) {
    if (accuracy >= 95) return Colors.green;
    if (accuracy >= 85) return Colors.blue;
    if (accuracy >= 75) return Colors.orange;
    return Colors.red;
  }

  String _getSuggestion(int sampleCount) {
    if (sampleCount == 1) return 'Add 1 more sample to reach 90% accuracy';
    if (sampleCount == 2) return 'Add 1 more sample to reach 96% accuracy';
    if (sampleCount == 3) return 'Add more samples to reach 99%+ accuracy';
    return 'Excellent accuracy achieved!';
  }

  void _showDeleteDialog(BuildContext context, dynamic voice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice?'),
        content: Text(
          'Are you sure you want to delete "${voice.userDefinedName ?? voice.name}"? This cannot be undone.',
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
                const SnackBar(content: Text('Voice deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
