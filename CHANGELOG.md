# Changelog

## 0.1.0

First release.

- Cross-platform YouTube playback on Windows, macOS, Linux, ChromeOS, Android,
  iOS, and web, backed by youtube_explode_dart and media_kit (libmpv).
- `UniversalYoutubePlayer` widget that accepts either a link or a controller,
  with configurable aspect ratio, fit, controls, and loading and error
  builders.
- `UniversalYoutubeController` with play, pause, seek, relative seek, replay,
  volume, mute, playback speed, looping, and live runtime quality switching
  that preserves the current position.
- Playback state exposed as streams (position, duration, buffer, playing,
  buffering, completed, volume, rate) and as a `ChangeNotifier` for status,
  errors, and metadata.
- Quality selection with `low`, `medium`, `high`, and `best`, plus automatic
  HLS handling for live videos.
- URL helpers `extractYoutubeVideoId` and `isYoutubeVideoUrl`.
