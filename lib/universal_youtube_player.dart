/// Play any YouTube video on every Flutter platform: Windows, macOS, Linux,
/// ChromeOS, Android, iOS and the web.
///
/// Call [UniversalYoutubePlayerBootstrap.ensureInitialized] once in `main`
/// before `runApp`, then use [UniversalYoutubePlayer] or drive playback with a
/// [UniversalYoutubeController].
///
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   UniversalYoutubePlayerBootstrap.ensureInitialized();
///   runApp(const MyApp());
/// }
/// ```
///
/// ```dart
/// UniversalYoutubePlayer(url: 'https://youtu.be/dQw4w9WgXcQ')
/// ```
library;

import 'package:media_kit/media_kit.dart';

export 'src/youtube_client.dart';
export 'src/youtube_metadata.dart';
export 'src/youtube_player.dart';
export 'src/youtube_player_controller.dart';
export 'src/youtube_player_exception.dart';
export 'src/youtube_url.dart';
export 'src/youtube_video_quality.dart';

/// One time setup for the native media backend.
abstract final class UniversalYoutubePlayerBootstrap {
  static bool _initialized = false;

  /// Initializes the native backend used for playback.
  ///
  /// Call this after `WidgetsFlutterBinding.ensureInitialized` and before
  /// creating a [UniversalYoutubeController] or [UniversalYoutubePlayer].
  /// Calling it more than once is safe and has no additional effect.
  static void ensureInitialized() {
    if (_initialized) return;
    MediaKit.ensureInitialized();
    _initialized = true;
  }
}
