import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'youtube_metadata.dart';
import 'youtube_url.dart';
import 'youtube_video_quality.dart';

/// The stage of a [UniversalYoutubeController] in its load and play cycle.
enum YoutubePlayerStatus {
  /// Nothing has been loaded yet.
  idle,

  /// A link is being turned into a playable stream.
  resolving,

  /// A stream is loaded and ready to play.
  ready,

  /// Loading or playback failed. See [UniversalYoutubeController.error].
  error,
}

/// Drives YouTube playback on every Flutter platform, including Windows,
/// macOS, Linux, ChromeOS, Android, iOS and the web.
///
/// The controller turns a YouTube link into a direct media stream with
/// `youtube_explode_dart`, then plays it through `media_kit`. There is no
/// embedded web view and no API key to manage.
///
/// A controller wraps a single [Player]. Create one per video surface, load a
/// link, and dispose it when you are done.
///
/// ```dart
/// final controller = UniversalYoutubeController();
/// await controller.load('https://youtu.be/dQw4w9WgXcQ');
///
/// // Later, react to playback progress:
/// controller.positionStream.listen((position) => print(position));
///
/// // And when finished:
/// controller.dispose();
/// ```
///
/// The controller extends [ChangeNotifier] and notifies listeners when
/// [status], [error] or [metadata] change. High frequency values such as the
/// playback position are exposed as streams instead, so widgets can rebuild
/// only the parts that depend on them.
class UniversalYoutubeController extends ChangeNotifier {
  /// Creates a controller and its underlying [Player].
  ///
  /// Pass a [playerConfiguration] or [videoControllerConfiguration] to tune the
  /// native backend. Supply a [youtubeExplode] instance to share one HTTP
  /// client across controllers; when omitted the controller creates and owns
  /// its own and closes it on [dispose].
  UniversalYoutubeController({
    PlayerConfiguration playerConfiguration = const PlayerConfiguration(),
    VideoControllerConfiguration videoControllerConfiguration =
        const VideoControllerConfiguration(),
    YoutubeExplode? youtubeExplode,
  }) : _yt = youtubeExplode ?? YoutubeExplode(),
       _ownsYt = youtubeExplode == null,
       player = Player(configuration: playerConfiguration) {
    videoController = VideoController(
      player,
      configuration: videoControllerConfiguration,
    );
  }

  /// The `media_kit` player behind this controller.
  ///
  /// Use it for behaviour the controller does not wrap directly, such as
  /// audio device selection or subtitle tracks.
  final Player player;

  /// The `media_kit` video controller consumed by [UniversalYoutubePlayer].
  late final VideoController videoController;

  final YoutubeExplode _yt;
  final bool _ownsYt;

  YoutubePlayerStatus _status = YoutubePlayerStatus.idle;
  Object? _error;
  YoutubeMetadata? _metadata;
  YoutubeVideoQuality _quality = YoutubeVideoQuality.high;
  String? _lastInput;
  bool _looping = false;
  double _volumeBeforeMute = 100;
  bool _muted = false;
  int _loadToken = 0;
  bool _disposed = false;

  /// The current stage of the load and play cycle.
  YoutubePlayerStatus get status => _status;

  /// The last error thrown while loading or playing, or `null` if there is
  /// none. Set when [status] becomes [YoutubePlayerStatus.error].
  Object? get error => _error;

  /// Details about the loaded video, or `null` before the first successful
  /// load.
  YoutubeMetadata? get metadata => _metadata;

  /// The quality used for the most recent [load].
  YoutubeVideoQuality get quality => _quality;

  /// Whether the current video repeats when it reaches the end.
  bool get isLooping => _looping;

  /// Whether audio is currently muted.
  bool get isMuted => _muted;

  /// The current playback position.
  Duration get position => player.state.position;

  /// The total duration, or [Duration.zero] while unknown.
  Duration get duration => player.state.duration;

  /// Whether the player is currently playing.
  bool get isPlaying => player.state.playing;

  /// Whether the player is buffering.
  bool get isBuffering => player.state.buffering;

  /// The current volume, from 0 to 100.
  double get volume => player.state.volume;

  /// The current playback speed, where 1.0 is normal speed.
  double get rate => player.state.rate;

  /// Emits the playback position as it advances.
  Stream<Duration> get positionStream => player.stream.position;

  /// Emits the total duration once it is known.
  Stream<Duration> get durationStream => player.stream.duration;

  /// Emits the buffered position.
  Stream<Duration> get bufferStream => player.stream.buffer;

  /// Emits `true` while playing and `false` while paused.
  Stream<bool> get playingStream => player.stream.playing;

  /// Emits `true` while the player is buffering.
  Stream<bool> get bufferingStream => player.stream.buffering;

  /// Emits `true` once the current video plays to the end.
  Stream<bool> get completedStream => player.stream.completed;

  /// Emits the volume whenever it changes.
  Stream<double> get volumeStream => player.stream.volume;

  /// Emits the playback speed whenever it changes.
  Stream<double> get rateStream => player.stream.rate;

  /// Resolves [urlOrVideoId] and begins playing it.
  ///
  /// Accepts any of the link shapes handled by [extractYoutubeVideoId] or a
  /// bare video id. Set [autoPlay] to `false` to load without starting.
  /// [quality] selects the requested resolution. [startAt] seeks to a position
  /// before playback begins. [volume] and [muted] set the initial audio state,
  /// and [looping] makes the video repeat.
  ///
  /// Throws an [ArgumentError] if [urlOrVideoId] is not a valid YouTube link,
  /// and rethrows any error raised while resolving or opening the stream after
  /// exposing it through [status] and [error].
  Future<void> load(
    String urlOrVideoId, {
    bool autoPlay = true,
    YoutubeVideoQuality quality = YoutubeVideoQuality.high,
    Duration? startAt,
    double? volume,
    bool muted = false,
    bool looping = false,
  }) async {
    final id = extractYoutubeVideoId(urlOrVideoId);
    if (id == null) {
      throw ArgumentError.value(
        urlOrVideoId,
        'urlOrVideoId',
        'Not a valid YouTube video link or id',
      );
    }

    final videoId = VideoId(id);
    final token = ++_loadToken;
    _lastInput = urlOrVideoId;
    _quality = quality;
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

      await player.open(
        Media(resolved.videoUrl, start: startAt),
        play: autoPlay,
      );
      if (_isStale(token)) return;

      if (resolved.audioUrl != null) {
        await player.setAudioTrack(AudioTrack.uri(resolved.audioUrl!));
        if (_isStale(token)) return;
      }

      await setLooping(looping);
      if (volume != null) await setVolume(volume);
      if (muted) await setMuted(true);

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
    if (isLive) {
      final hlsUrl = await _yt.videos.streamsClient.getHttpLiveStreamUrl(
        videoId,
      );
      return _ResolvedStream(videoUrl: hlsUrl);
    }

    final manifest = await _yt.videos.streamsClient.getManifest(videoId);

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

    final muxed = manifest.muxed.sortByVideoQuality();
    if (muxed.isNotEmpty) {
      final chosen = switch (quality) {
        YoutubeVideoQuality.low => muxed.last,
        YoutubeVideoQuality.medium => muxed[muxed.length ~/ 2],
        YoutubeVideoQuality.high || YoutubeVideoQuality.best => muxed.first,
      };
      return _ResolvedStream(videoUrl: chosen.url.toString());
    }

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

  /// Reloads the current video at [quality], keeping the playback position and
  /// play state. Does nothing if no video has been loaded.
  Future<void> setQuality(YoutubeVideoQuality quality) async {
    final input = _lastInput;
    if (input == null || quality == _quality) return;
    final resumeAt = position;
    final wasPlaying = isPlaying;
    await load(
      input,
      quality: quality,
      autoPlay: wasPlaying,
      startAt: resumeAt,
      looping: _looping,
      muted: _muted,
    );
  }

  /// Starts or resumes playback.
  Future<void> play() => player.play();

  /// Pauses playback.
  Future<void> pause() => player.pause();

  /// Toggles between playing and paused.
  Future<void> playOrPause() => player.playOrPause();

  /// Stops playback and unloads the current media.
  Future<void> stop() => player.stop();

  /// Restarts the current video from the beginning.
  Future<void> replay() async {
    await seek(Duration.zero);
    await play();
  }

  /// Seeks to [position] within the current video.
  Future<void> seek(Duration position) => player.seek(position);

  /// Seeks by [offset] relative to the current position, clamped to the video
  /// bounds. Use a negative [offset] to rewind.
  Future<void> seekBy(Duration offset) {
    final target = position + offset;
    final total = duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (total > Duration.zero && target > total ? total : target);
    return seek(clamped);
  }

  /// Sets the volume, from 0 to 100. Unmutes if audio was muted.
  Future<void> setVolume(double volume) async {
    _muted = false;
    await player.setVolume(volume.clamp(0, 100));
  }

  /// Sets the playback speed, where 1.0 is normal speed.
  Future<void> setRate(double rate) => player.setRate(rate);

  /// Mutes or unmutes audio, restoring the previous volume on unmute.
  Future<void> setMuted(bool muted) async {
    if (muted == _muted) return;
    if (muted) {
      _volumeBeforeMute = volume;
      await player.setVolume(0);
    } else {
      await player.setVolume(_volumeBeforeMute);
    }
    _muted = muted;
    notifyListeners();
  }

  /// Toggles the muted state.
  Future<void> toggleMute() => setMuted(!_muted);

  /// Sets whether the current video repeats when it ends.
  Future<void> setLooping(bool looping) async {
    _looping = looping;
    await player.setPlaylistMode(
      looping ? PlaylistMode.single : PlaylistMode.none,
    );
    notifyListeners();
  }

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
