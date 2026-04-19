import 'package:flutter/material.dart';
import '../models/voice.dart';

/// Home screen with two tabs: Predefined Voices and My Custom Voices
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Converter'),
        elevation: 0,
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
class CustomVoicesTab extends StatelessWidget {
  const CustomVoicesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

          // Record or Upload Options
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Record voice feature - Coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mic),
                  label: const Text('Record'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Upload from storage - Coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // My Custom Voices Section
          Text(
            'My Custom Voices',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Placeholder for custom voices list
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.person_add_alt, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No custom voices yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Record or upload a voice to get started',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
