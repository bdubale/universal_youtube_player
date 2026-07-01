import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'youtube_player_controller.dart';
import 'youtube_video_quality.dart';

/// A cross-platform YouTube video player widget.
///
/// Provide a [url] for the simple case — the widget owns and drives its own
/// [UniversalYoutubeController] — or pass an existing [controller] when you
/// need to drive playback yourself.
///
/// ```dart
/// // Simplest usage:
/// UniversalYoutubePlayer(url: 'https://youtu.be/dQw4w9WgXcQ')
///
/// // With your own controller:
/// UniversalYoutubePlayer(controller: myController)
/// ```
class UniversalYoutubePlayer extends StatefulWidget {
  const UniversalYoutubePlayer({
    super.key,
    this.url,
    this.controller,
    this.autoPlay = true,
    this.quality = YoutubeVideoQuality.high,
    this.aspectRatio = 16 / 9,
    this.controls = true,
    this.placeholder,
    this.errorBuilder,
    this.loadingBuilder,
  }) : assert(
          (url != null) ^ (controller != null),
          'Provide exactly one of `url` or `controller`.',
        );

  /// A YouTube link (any form) or bare video id to play. Mutually exclusive
  /// with [controller].
  final String? url;

  /// An externally-owned controller. Mutually exclusive with [url]. When
  /// supplied, the caller is responsible for calling `load` and `dispose`.
  final UniversalYoutubeController? controller;

  /// Whether playback starts automatically once resolved. Only used when [url]
  /// is provided.
  final bool autoPlay;

  /// Preferred quality. Only used when [url] is provided.
  final YoutubeVideoQuality quality;

  /// Aspect ratio of the video surface.
  final double aspectRatio;

  /// Whether to show the default media controls overlay.
  final bool controls;

  /// Widget shown before playback begins (behind the video surface).
  final Widget? placeholder;

  /// Builds the widget shown when resolving or playback fails.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Builds the widget shown while the link is being resolved.
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
    if (_ownsController) {
      _controller.load(
        widget.url!,
        autoPlay: widget.autoPlay,
        quality: widget.quality,
      );
    }
  }

  @override
  void didUpdateWidget(covariant UniversalYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when the widget owns the controller and the url changed.
    if (_ownsController &&
        widget.url != null &&
        widget.url != oldWidget.url) {
      _controller.load(
        widget.url!,
        autoPlay: widget.autoPlay,
        quality: widget.quality,
      );
    }
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
                  _DefaultError(error: error);
            case YoutubePlayerStatus.idle:
            case YoutubePlayerStatus.resolving:
              return widget.loadingBuilder?.call(context) ??
                  widget.placeholder ??
                  const _DefaultLoading();
            case YoutubePlayerStatus.ready:
              return Video(
                controller: _controller.videoController,
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

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 8),
              Text(
                'Could not play this video.\n$error',
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
