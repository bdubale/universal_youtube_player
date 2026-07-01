import 'package:flutter/material.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  UniversalYoutubePlayerBootstrap.ensureInitialized();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal YouTube Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _controller = UniversalYoutubeController();
  final _urlField = TextEditingController(
    text: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  );

  @override
  void initState() {
    super.initState();
    _play();
  }

  Future<void> _play() async {
    final url = _urlField.text.trim();
    if (url.isEmpty) return;
    try {
      await _controller.load(url, quality: YoutubeVideoQuality.high);
    } catch (_) {
      // Errors surface through the player's error state; nothing to do here.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _urlField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Universal YouTube Player')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlField,
                        decoration: const InputDecoration(
                          labelText: 'YouTube link',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _play(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _play,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: UniversalYoutubePlayer(controller: _controller),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final meta = _controller.metadata;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${_controller.status.name}'),
                        if (meta != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(meta.author),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// The SingleChildScrollView above keeps the demo usable in short windows.
