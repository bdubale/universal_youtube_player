# Changelog

## 0.2.0

- Resolve streams across several YouTube clients in order, which gets past many
  of the bot checks that block a single client (common on VPN and datacenter
  IPs). Pick the clients with the new `clients` option on the controller and on
  `load`; the default is `defaultYoutubeClients`.
- Classify failures into a `YoutubePlayerException` with a `YoutubePlayerErrorKind`
  (unavailable, geoRestricted, requiresPurchase, botCheck, noStreams, network,
  unknown), an `isRetryable` flag, and a user-facing `hint`. The controller now
  stores and throws this typed error, and the widget's default error view shows
  the hint.
- Runtime quality switching reuses the client list from the last load.
- Example app shows the failure kind and a retry button for retryable errors.

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
