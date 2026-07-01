/// Play any YouTube video on every Flutter platform — Windows, macOS, Linux,
/// ChromeOS, Android, iOS and web — using native libmpv playback.
///
/// Call [UniversalYoutubePlayerBootstrap.ensureInitialized] once in `main()`
/// before `runApp`:
///
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   UniversalYoutubePlayerBootstrap.ensureInitialized();
///   runApp(const MyApp());
/// }
/// ```
///
/// Then drop in a player:
///
/// ```dart
/// UniversalYoutubePlayer(url: 'https://youtu.be/dQw4w9WgXcQ')
/// ```
library;

import 'package:media_kit/media_kit.dart';

export 'src/youtube_metadata.dart';
export 'src/youtube_player.dart';
export 'src/youtube_player_controller.dart';
export 'src/youtube_video_quality.dart';

/// One-time initialization for the native media backend.
abstract final class UniversalYoutubePlayerBootstrap {
  static bool _initialized = false;

  /// Initializes the underlying `media_kit` backend. Safe to call more than
  /// once; only the first call has an effect. Must run after
  /// `WidgetsFlutterBinding.ensureInitialized()` and before creating any
  /// `UniversalYoutubeController` or `UniversalYoutubePlayer`.
  static void ensureInitialized() {
    if (_initialized) return;
    MediaKit.ensureInitialized();
    _initialized = true;
  }
}
