import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voice.dart';
import '../providers/voice_provider.dart';
import 'voice_input_screen.dart';

/// Voice Detail Screen - View and manage individual voice
class VoiceDetailScreen extends ConsumerStatefulWidget {
  final Voice voice;

  const VoiceDetailScreen({
    Key? key,
    required this.voice,
  }) : super(key: key);

  @override
  ConsumerState<VoiceDetailScreen> createState() => _VoiceDetailScreenState();
}

class _VoiceDetailScreenState extends ConsumerState<VoiceDetailScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.voice.userDefinedName ?? widget.voice.name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = widget.voice;
    final accuracy = voice.accuracyPercentage.toInt();
    final samples = voice.sampleCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Details'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () {
                  _showDeleteDialog();
                },
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Delete Voice'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voice Name Section
              Text(
                'Voice Name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter voice name',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Accuracy Section
              Text(
                'Accuracy & Quality',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Accuracy Card
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Accuracy',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '$accuracy%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getAccuracyColor(accuracy),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: accuracy / 100,
                        minHeight: 12,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation(
                          _getAccuracyColor(accuracy),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Samples Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      icon: Icons.mic,
                      label: 'Samples',
                      value: samples.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      icon: Icons.target,
                      label: 'Quality',
                      value: _getQualityLabel(accuracy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Improvement Guide
              Text(
                'Improve Your Voice',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              if (accuracy < 99)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getImprovement(samples),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Perfect! Your voice is 99%+ accurate.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Sample Breakdown
              Text(
                'Sample Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildAccuracyProgression(context, samples),
              const SizedBox(height: 32),

              // Add Sample Button
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
                  label: const Text('Add More Samples'),
                ),
              ),
              const SizedBox(height: 16),

              // Use Voice Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.tonal(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Using "${_nameController.text}"'),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Use This Voice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyProgression(BuildContext context, int samples) {
    final milestones = [
      (1, 80, 'Basic'),
      (2, 90, 'Good'),
      (3, 96, 'Very Good'),
      (4, 99, 'Perfect'),
    ];

    return Column(
      children: milestones.map((m) {
        final (sampleCount, accuracy, label) = m;
        final isReached = samples >= sampleCount;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isReached
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: isReached ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isReached
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isReached
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isReached
                        ? const Icon(Icons.check, color: Colors.white)
                        : Text('$sampleCount'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$sampleCount Sample${sampleCount > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '$accuracy% - $label',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getAccuracyColor(int accuracy) {
    if (accuracy >= 95) return Colors.green;
    if (accuracy >= 85) return Colors.blue;
    if (accuracy >= 75) return Colors.orange;
    return Colors.red;
  }

  String _getQualityLabel(int accuracy) {
    if (accuracy >= 95) return 'Perfect';
    if (accuracy >= 85) return 'Very Good';
    if (accuracy >= 75) return 'Good';
    return 'Basic';
  }

  String _getImprovement(int samples) {
    if (samples == 0) return 'Add your first sample to get started!';
    if (samples == 1) return 'Add 1 more sample to improve accuracy to 90%';
    if (samples == 2) return 'Add 1 more sample to improve accuracy to 96%';
    if (samples == 3) return 'Add more samples to reach 99%+ accuracy';
    return 'Excellent! Your voice is nearly perfect.';
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice?'),
        content: Text(
          'Are you sure you want to delete "${_nameController.text}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
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
