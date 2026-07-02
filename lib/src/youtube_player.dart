import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'youtube_player_controller.dart';
import 'youtube_player_exception.dart';
import 'youtube_video_quality.dart';

/// A cross platform YouTube video player.
///
/// Give the widget a [url] and it manages its own controller, or pass a
/// [controller] you own and drive playback yourself. Exactly one of the two is
/// required.
///
/// ```dart
/// // Self managed, the common case:
/// UniversalYoutubePlayer(url: 'https://youtu.be/dQw4w9WgXcQ')
///
/// // With your own controller, for custom controls or shared state:
/// UniversalYoutubePlayer(controller: myController)
/// ```
///
/// The widget shows a loading indicator while the link resolves and an error
/// view if it fails. Override [loadingBuilder], [placeholder] and
/// [errorBuilder] to match your app.
class UniversalYoutubePlayer extends StatefulWidget {
  /// Creates a player.
  ///
  /// Provide either [url] or [controller], never both and never neither.
  const UniversalYoutubePlayer({
    super.key,
    this.url,
    this.controller,
    this.autoPlay = true,
    this.quality = YoutubeVideoQuality.high,
    this.looping = false,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.contain,
    this.backgroundColor = Colors.black,
    this.controls = true,
    this.placeholder,
    this.errorBuilder,
    this.loadingBuilder,
  }) : assert(
         (url == null) != (controller == null),
         'Provide exactly one of url or controller.',
       );

  /// A YouTube link or bare video id to play. Mutually exclusive with
  /// [controller].
  final String? url;

  /// A controller you own and dispose yourself. Mutually exclusive with [url].
  final UniversalYoutubeController? controller;

  /// Whether playback starts as soon as the link resolves. Only used when
  /// [url] is set.
  final bool autoPlay;

  /// The quality to request. Only used when [url] is set.
  final YoutubeVideoQuality quality;

  /// Whether the video repeats when it ends. Only used when [url] is set.
  final bool looping;

  /// The aspect ratio of the video surface.
  final double aspectRatio;

  /// How the video fills its surface.
  final BoxFit fit;

  /// The color painted behind the video.
  final Color backgroundColor;

  /// Whether to show the built in playback controls.
  final bool controls;

  /// A widget shown behind the video before playback begins. Falls back to a
  /// plain colored surface.
  final Widget? placeholder;

  /// Builds the view shown when loading or playback fails.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Builds the view shown while the link is resolving.
  final Widget Function(BuildContext context)? loadingBuilder;

  @override
  State<UniversalYoutubePlayer> createState() => _UniversalYoutubePlayerState();
}

class _UniversalYoutubePlayerState extends State<UniversalYoutubePlayer> {
  late final UniversalYoutubeController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? UniversalYoutubeController();
    if (_ownsController) _loadFromUrl();
  }

  @override
  void didUpdateWidget(covariant UniversalYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ownsController && widget.url != oldWidget.url && widget.url != null) {
      _loadFromUrl();
    }
  }

  void _loadFromUrl() {
    _controller
        .load(
          widget.url!,
          autoPlay: widget.autoPlay,
          quality: widget.quality,
          looping: widget.looping,
        )
        .catchError((_) {});
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          switch (_controller.status) {
            case YoutubePlayerStatus.error:
              final error = _controller.error ?? 'Unknown error';
              return widget.errorBuilder?.call(context, error) ??
                  _ErrorView(error: error, background: widget.backgroundColor);
            case YoutubePlayerStatus.idle:
            case YoutubePlayerStatus.resolving:
              return widget.loadingBuilder?.call(context) ??
                  widget.placeholder ??
                  _LoadingView(background: widget.backgroundColor);
            case YoutubePlayerStatus.ready:
              return Video(
                controller: _controller.videoController,
                fit: widget.fit,
                fill: widget.backgroundColor,
                controls: widget.controls
                    ? AdaptiveVideoControls
                    : NoVideoControls,
              );
          }
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.background});

  final Color background;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.background});

  final Object error;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final message = error is YoutubePlayerException
        ? (error as YoutubePlayerException).hint
        : 'This video could not be played.';
    return ColoredBox(
      color: background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
