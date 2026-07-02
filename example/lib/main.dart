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
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

const _samples = <(String, String)>[
  ('Flutter promo', 'https://www.youtube.com/watch?v=fq4N0hgOWzU'),
  ('Big Buck Bunny', 'https://youtu.be/aqz-KE-bpKQ'),
  ('Short', 'https://www.youtube.com/shorts/tPEE9ZwTmy0'),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = UniversalYoutubeController();
  final _urlField = TextEditingController(text: _samples.first.$2);

  @override
  void initState() {
    super.initState();
    _load(_urlField.text);
  }

  Future<void> _load(String url) async {
    _urlField.text = url;
    try {
      await _controller.load(url, quality: YoutubeVideoQuality.high);
    } catch (_) {}
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _UrlBar(controller: _urlField, onSubmit: _load),
              const SizedBox(height: 12),
              _SampleChips(onSelected: _load),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: UniversalYoutubePlayer(controller: _controller),
              ),
              const SizedBox(height: 16),
              PlayerControls(controller: _controller),
              const SizedBox(height: 16),
              MetadataCard(
                controller: _controller,
                onRetry: () => _load(_urlField.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UrlBar extends StatelessWidget {
  const _UrlBar({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'YouTube link or video id',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.link),
            ),
            onSubmitted: onSubmit,
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () => onSubmit(controller.text),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Load'),
        ),
      ],
    );
  }
}

class _SampleChips extends StatelessWidget {
  const _SampleChips({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final (label, url) in _samples)
          ActionChip(
            avatar: const Icon(Icons.movie_outlined, size: 18),
            label: Text(label),
            onPressed: () => onSelected(url),
          ),
      ],
    );
  }
}

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key, required this.controller});

  final UniversalYoutubeController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _ScrubBar(controller: controller),
            _TransportRow(controller: controller),
            const Divider(height: 24),
            _VolumeRow(controller: controller),
            const SizedBox(height: 8),
            _SettingsRow(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _ScrubBar extends StatelessWidget {
  const _ScrubBar({required this.controller});

  final UniversalYoutubeController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: controller.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = controller.duration;
        final maxMs = total.inMilliseconds.toDouble();
        final value = maxMs == 0
            ? 0.0
            : position.inMilliseconds.toDouble().clamp(0, maxMs);
        return Column(
          children: [
            Slider(
              value: value.toDouble(),
              max: maxMs == 0 ? 1 : maxMs,
              onChanged: maxMs == 0
                  ? null
                  : (v) => controller.seek(Duration(milliseconds: v.round())),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(_fmt(position)), Text(_fmt(total))],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow({required this.controller});

  final UniversalYoutubeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Restart',
          icon: const Icon(Icons.replay),
          onPressed: controller.replay,
        ),
        IconButton(
          tooltip: 'Back 10s',
          icon: const Icon(Icons.replay_10),
          onPressed: () => controller.seekBy(const Duration(seconds: -10)),
        ),
        StreamBuilder<bool>(
          stream: controller.playingStream,
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;
            return IconButton.filled(
              iconSize: 32,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: controller.playOrPause,
            );
          },
        ),
        IconButton(
          tooltip: 'Forward 10s',
          icon: const Icon(Icons.forward_10),
          onPressed: () => controller.seekBy(const Duration(seconds: 10)),
        ),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) => IconButton(
            tooltip: controller.isLooping ? 'Looping on' : 'Looping off',
            isSelected: controller.isLooping,
            icon: const Icon(Icons.repeat),
            selectedIcon: const Icon(Icons.repeat_on),
            onPressed: () => controller.setLooping(!controller.isLooping),
          ),
        ),
      ],
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.controller});

  final UniversalYoutubeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final muted = controller.isMuted;
        return Row(
          children: [
            IconButton(
              tooltip: muted ? 'Unmute' : 'Mute',
              icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
              onPressed: controller.toggleMute,
            ),
            Expanded(
              child: StreamBuilder<double>(
                stream: controller.volumeStream,
                builder: (context, snapshot) {
                  final volume = snapshot.data ?? controller.volume;
                  return Slider(
                    value: volume.clamp(0, 100),
                    max: 100,
                    label: '${volume.round()}%',
                    onChanged: controller.setVolume,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.controller});

  final UniversalYoutubeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.high_quality, size: 20),
                const SizedBox(width: 8),
                DropdownButton<YoutubeVideoQuality>(
                  value: controller.quality,
                  onChanged: (q) {
                    if (q != null) controller.setQuality(q);
                  },
                  items: [
                    for (final q in YoutubeVideoQuality.values)
                      DropdownMenuItem(value: q, child: Text(q.name)),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed, size: 20),
                const SizedBox(width: 8),
                StreamBuilder<double>(
                  stream: controller.rateStream,
                  builder: (context, snapshot) {
                    final rate = snapshot.data ?? controller.rate;
                    return DropdownButton<double>(
                      value: _nearestRate(rate),
                      onChanged: (r) {
                        if (r != null) controller.setRate(r);
                      },
                      items: const [
                        DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                        DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                        DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                        DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class MetadataCard extends StatelessWidget {
  const MetadataCard({
    super.key,
    required this.controller,
    required this.onRetry,
  });

  final UniversalYoutubeController controller;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final error = controller.error;
        if (controller.status == YoutubePlayerStatus.error) {
          final kind = error is YoutubePlayerException
              ? error.kind.name
              : 'error';
          final hint = error is YoutubePlayerException
              ? error.hint
              : 'The video could not be played.';
          final retryable =
              error is YoutubePlayerException && error.isRetryable;
          return Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text('Playback failed ($kind)'),
              subtitle: Text(hint),
              trailing: retryable
                  ? TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    )
                  : null,
            ),
          );
        }

        final meta = controller.metadata;
        return Card(
          child: ListTile(
            leading: _statusIcon(controller.status),
            title: Text(meta?.title ?? 'No video loaded'),
            subtitle: Text(
              meta == null
                  ? controller.status.name
                  : '${meta.author}  ·  ${controller.status.name}'
                        '${meta.isLive ? '  ·  LIVE' : ''}',
            ),
          ),
        );
      },
    );
  }
}

Widget _statusIcon(YoutubePlayerStatus status) => switch (status) {
  YoutubePlayerStatus.idle => const Icon(Icons.hourglass_empty),
  YoutubePlayerStatus.resolving => const SizedBox.square(
    dimension: 24,
    child: CircularProgressIndicator(strokeWidth: 2),
  ),
  YoutubePlayerStatus.ready => const Icon(
    Icons.check_circle,
    color: Colors.green,
  ),
  YoutubePlayerStatus.error => const Icon(Icons.error, color: Colors.red),
};

double _nearestRate(double rate) {
  const rates = [0.5, 1.0, 1.5, 2.0];
  var nearest = rates.first;
  for (final r in rates) {
    if ((r - rate).abs() < (nearest - rate).abs()) nearest = r;
  }
  return nearest;
}

String _fmt(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
