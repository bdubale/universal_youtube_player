import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'youtube_metadata.dart';
import 'youtube_video_quality.dart';

/// Lifecycle status of a [UniversalYoutubeController].
enum YoutubePlayerStatus {
  /// No media has been requested yet.
  idle,

  /// Resolving the YouTube link into a playable stream.
  resolving,

  /// A stream was resolved and handed to the native player.
  ready,

  /// Resolving or playback failed. Inspect [UniversalYoutubeController.error].
  error,
}

/// Controls YouTube playback backed by libmpv (via `media_kit`) on every
/// Flutter platform: Windows, macOS, Linux, ChromeOS, Android, iOS and web.
///
/// The controller resolves a YouTube link into a direct media stream with
/// `youtube_explode_dart`, then plays it natively — no embedded WebView and
/// no YouTube Data API key required.
///
/// ```dart
/// final controller = UniversalYoutubeController();
/// await controller.load('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
/// // ... UniversalYoutubePlayer(controller: controller)
/// controller.dispose();
/// ```
class UniversalYoutubeController extends ChangeNotifier {
  UniversalYoutubeController({
    PlayerConfiguration playerConfiguration = const PlayerConfiguration(),
    VideoControllerConfiguration videoControllerConfiguration =
        const VideoControllerConfiguration(),
    YoutubeExplode? youtubeExplode,
  })  : _yt = youtubeExplode ?? YoutubeExplode(),
        _ownsYt = youtubeExplode == null,
        player = Player(configuration: playerConfiguration) {
    videoController = VideoController(
      player,
      configuration: videoControllerConfiguration,
    );
  }

  /// The underlying `media_kit` player. Exposed for advanced control and for
  /// building custom UIs; most callers only need the convenience methods.
  final Player player;

  /// The `media_kit_video` controller consumed by [UniversalYoutubePlayer].
  late final VideoController videoController;

  final YoutubeExplode _yt;
  final bool _ownsYt;

  YoutubePlayerStatus _status = YoutubePlayerStatus.idle;
  YoutubePlayerStatus get status => _status;

  Object? _error;

  /// The last error thrown while resolving or loading, or `null`.
  Object? get error => _error;

  YoutubeMetadata? _metadata;

  /// Metadata for the currently-loaded video, or `null`.
  YoutubeMetadata? get metadata => _metadata;

  /// Monotonic token guarding against out-of-order [load] calls.
  int _loadToken = 0;

  bool _disposed = false;

  /// Resolves [urlOrVideoId] (any YouTube link form or a bare 11-char id) into
  /// a playable stream and hands it to the native player.
  ///
  /// Set [autoPlay] to begin playback immediately. [quality] selects among the
  /// available muxed streams; [YoutubeVideoQuality.best] additionally combines
  /// a video-only stream with a separate audio track on native platforms for
  /// resolutions above what muxed streams offer.
  ///
  /// Throws [ArgumentError] when [urlOrVideoId] is not a valid YouTube link.
  Future<void> load(
    String urlOrVideoId, {
    bool autoPlay = true,
    YoutubeVideoQuality quality = YoutubeVideoQuality.high,
  }) async {
    final parsed = VideoId.parseVideoId(urlOrVideoId);
    if (parsed == null) {
      throw ArgumentError.value(
        urlOrVideoId,
        'urlOrVideoId',
        'Not a recognizable YouTube video link or id',
      );
    }
    final videoId = VideoId(parsed);
    final token = ++_loadToken;

    _error = null;
    _setStatus(YoutubePlayerStatus.resolving);

    try {
      final video = await _yt.videos.get(videoId);
      if (_isStale(token)) return;

      _metadata = YoutubeMetadata(
        videoId: videoId.value,
        title: video.title,
        author: video.author,
        isLive: video.isLive,
        duration: video.duration,
        thumbnailUrl: video.thumbnails.highResUrl,
      );
      notifyListeners();

      final resolved = await _resolveStream(videoId, video.isLive, quality);
      if (_isStale(token)) return;

      await player.open(Media(resolved.videoUrl), play: autoPlay);
      if (_isStale(token)) return;

      // Attach a separate audio track for high-resolution video-only streams.
      if (resolved.audioUrl != null) {
        await player.setAudioTrack(AudioTrack.uri(resolved.audioUrl!));
      }
      if (_isStale(token)) return;

      _setStatus(YoutubePlayerStatus.ready);
    } catch (e) {
      if (_isStale(token)) return;
      _error = e;
      _setStatus(YoutubePlayerStatus.error);
      rethrow;
    }
  }

  Future<_ResolvedStream> _resolveStream(
    VideoId videoId,
    bool isLive,
    YoutubeVideoQuality quality,
  ) async {
    // Live broadcasts are served as HLS, which libmpv plays natively.
    if (isLive) {
      final hlsUrl = await _yt.videos.streamsClient.getHttpLiveStreamUrl(
        videoId,
      );
      return _ResolvedStream(videoUrl: hlsUrl);
    }

    final manifest = await _yt.videos.streamsClient.getManifest(videoId);

    // `best` on native: pair the top video-only stream with the best audio.
    if (quality == YoutubeVideoQuality.best &&
        !kIsWeb &&
        manifest.videoOnly.isNotEmpty &&
        manifest.audioOnly.isNotEmpty) {
      final video = manifest.videoOnly.sortByVideoQuality().first;
      final audio = manifest.audioOnly.withHighestBitrate();
      return _ResolvedStream(
        videoUrl: video.url.toString(),
        audioUrl: audio.url.toString(),
      );
    }

    // Otherwise pick a single muxed (video + audio) stream — works everywhere.
    final muxed = manifest.muxed.sortByVideoQuality();
    if (muxed.isNotEmpty) {
      final chosen = switch (quality) {
        YoutubeVideoQuality.low => muxed.last,
        YoutubeVideoQuality.medium => muxed[muxed.length ~/ 2],
        YoutubeVideoQuality.high ||
        YoutubeVideoQuality.best =>
          muxed.first,
      };
      return _ResolvedStream(videoUrl: chosen.url.toString());
    }

    // Some videos expose no muxed streams; fall back to best-effort pairing.
    if (manifest.videoOnly.isNotEmpty) {
      final video = manifest.videoOnly.sortByVideoQuality().first;
      final audioUrl = manifest.audioOnly.isNotEmpty && !kIsWeb
          ? manifest.audioOnly.withHighestBitrate().url.toString()
          : null;
      return _ResolvedStream(
        videoUrl: video.url.toString(),
        audioUrl: audioUrl,
      );
    }

    throw StateError('No playable streams found for ${videoId.value}');
  }

  /// Begins or resumes playback.
  Future<void> play() => player.play();

  /// Pauses playback.
  Future<void> pause() => player.pause();

  /// Toggles between playing and paused.
  Future<void> playOrPause() => player.playOrPause();

  /// Stops playback and unloads the current media.
  Future<void> stop() => player.stop();

  /// Seeks to [position] within the current media.
  Future<void> seek(Duration position) => player.seek(position);

  /// Sets the volume in the range 0–100.
  Future<void> setVolume(double volume) => player.setVolume(volume);

  /// Sets the playback speed (1.0 = normal).
  Future<void> setRate(double rate) => player.setRate(rate);

  bool _isStale(int token) => _disposed || token != _loadToken;

  void _setStatus(YoutubePlayerStatus status) {
    if (_disposed || _status == status) return;
    _status = status;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _loadToken++;
    await player.dispose();
    if (_ownsYt) _yt.close();
    super.dispose();
  }
}

class _ResolvedStream {
  const _ResolvedStream({required this.videoUrl, this.audioUrl});

  final String videoUrl;
  final String? audioUrl;
}
