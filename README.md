# universal_youtube_player

Play **any YouTube video on every Flutter platform** — Windows, macOS, Linux,
ChromeOS, Android, iOS and web — with real native playback.

Unlike WebView-based YouTube players (which don't run on desktop), this package:

1. Resolves a YouTube link into a direct media stream with
   [`youtube_explode_dart`](https://pub.dev/packages/youtube_explode_dart)
   (no API key required), then
2. Plays it natively through [`media_kit`](https://pub.dev/packages/media_kit)
   (libmpv), which supports desktop, mobile and web.

## Features

- ✅ True desktop support: **Windows, macOS, Linux, ChromeOS** — plus Android, iOS & web
- ✅ Accepts any YouTube link form (`watch?v=`, `youtu.be/`, `/embed/`, `/shorts/`, or a bare id)
- ✅ Live-stream (HLS) playback
- ✅ Adjustable quality, including high-res video + separate audio on native
- ✅ Simple drop-in widget **and** a full controller for custom UIs
- ✅ Built-in adaptive playback controls

## Install

```yaml
dependencies:
  universal_youtube_player: ^0.1.0
```

## Setup

Initialize the native backend once in `main()`:

```dart
import 'package:flutter/material.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  UniversalYoutubePlayerBootstrap.ensureInitialized();
  runApp(const MyApp());
}
```

### macOS

Add the network-client entitlement to
`macos/Runner/DebugProfile.entitlements` **and** `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

### Linux

`media_kit` needs mpv libraries:

```bash
sudo apt install libmpv-dev mpv
```

## Usage

### Simplest — just a URL

```dart
UniversalYoutubePlayer(
  url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
)
```

### With a controller (play/pause/seek, metadata, quality)

```dart
final controller = UniversalYoutubeController();

await controller.load(
  'https://youtu.be/dQw4w9WgXcQ',
  autoPlay: true,
  quality: YoutubeVideoQuality.high,
);

// ... in your widget tree:
UniversalYoutubePlayer(controller: controller);

// Control playback:
await controller.playOrPause();
await controller.seek(const Duration(seconds: 30));
await controller.setRate(1.5);

// Metadata:
print(controller.metadata?.title);

// Always dispose a controller you own:
controller.dispose();
```

## API

| Type | Purpose |
| --- | --- |
| `UniversalYoutubePlayer` | Widget. Pass `url` (self-managed) or `controller`. |
| `UniversalYoutubeController` | `load`, `play`, `pause`, `playOrPause`, `stop`, `seek`, `setVolume`, `setRate`; exposes `status`, `error`, `metadata`, and the underlying `media_kit` `player`. |
| `YoutubeVideoQuality` | `low`, `medium`, `high`, `best`. |
| `YoutubeMetadata` | `title`, `author`, `isLive`, `duration`, `thumbnailUrl`. |

## Example

A complete demo app lives in [`example/`](example/lib/main.dart).

## How quality works

- `low` / `medium` / `high` pick from YouTube's **muxed** streams (single
  video+audio file) — supported on all platforms including web.
- `best` (native only) pairs the top **video-only** stream with the best audio
  track for resolutions above what muxed streams offer; falls back to `high`
  on web.
- Live videos always use the HLS master playlist.

## License

See [LICENSE](LICENSE).
