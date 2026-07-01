# universal_youtube_player

Play YouTube videos in a Flutter app on desktop, mobile, and web from a single
codebase.

Most YouTube plugins wrap the official iframe player in a web view, which
leaves desktop out because Flutter has no web view on Windows, macOS, or Linux.
This package takes a different route. It reads the direct media URLs for a video
with [youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart), then
plays them with [media_kit](https://pub.dev/packages/media_kit), a libmpv based
player that runs everywhere Flutter does. No web view, and no YouTube Data API
key.

## Supported platforms

| Platform | Status |
| --- | --- |
| Windows | Supported |
| macOS | Supported |
| Linux (including ChromeOS Linux) | Supported |
| Android | Supported |
| iOS | Supported |
| Web | Supported |

## Getting started

Add the dependency:

```yaml
dependencies:
  universal_youtube_player: ^0.1.0
```

Initialize the native backend once, before `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  UniversalYoutubePlayerBootstrap.ensureInitialized();
  runApp(const MyApp());
}
```

Drop a player into your widget tree:

```dart
UniversalYoutubePlayer(
  url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
)
```

That is the whole setup for the common case. The widget resolves the link,
shows a spinner while it works, and plays the video with a standard set of
controls.

## Platform setup

A few platforms need one time configuration.

### macOS

The app sandbox blocks outgoing connections by default, so add the network
client entitlement to both `macos/Runner/DebugProfile.entitlements` and
`macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

### Linux and ChromeOS

media_kit plays through libmpv, so install it and the build tooling:

```bash
sudo apt-get install libmpv-dev mpv
```

### Android

Add the internet permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Windows, iOS, Web

No extra setup.

## Driving playback yourself

Create a `UniversalYoutubeController` when you want to control playback, read
progress, or build your own UI. You own the controller, so call `dispose` when
the widget is gone.

```dart
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final controller = UniversalYoutubeController();

  @override
  void initState() {
    super.initState();
    controller.load(
      'https://youtu.be/dQw4w9WgXcQ',
      quality: YoutubeVideoQuality.high,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalYoutubePlayer(controller: controller);
  }
}
```

### Common actions

```dart
controller.playOrPause();
controller.seek(const Duration(minutes: 1));
controller.seekBy(const Duration(seconds: -10)); // rewind 10s
controller.setRate(1.5);
controller.setVolume(60);
controller.toggleMute();
controller.setLooping(true);
controller.setQuality(YoutubeVideoQuality.low); // reloads, keeps position
```

### Reacting to state

Status, errors, and metadata are exposed through `ChangeNotifier`, so an
`AnimatedBuilder` or `ListenableBuilder` rebuilds when they change:

```dart
AnimatedBuilder(
  animation: controller,
  builder: (context, _) {
    return Text(controller.metadata?.title ?? 'Loading...');
  },
)
```

Frequently changing values such as the position are streams, so you can
rebuild only the widgets that need them:

```dart
StreamBuilder<Duration>(
  stream: controller.positionStream,
  builder: (context, snapshot) {
    return Text('${snapshot.data ?? Duration.zero}');
  },
)
```

Available streams: `positionStream`, `durationStream`, `bufferStream`,
`playingStream`, `bufferingStream`, `completedStream`, `volumeStream`,
`rateStream`.

## Choosing quality

`load` and `setQuality` take a `YoutubeVideoQuality`:

- `low`, `medium`, and `high` pick from YouTube's combined streams, which carry
  video and audio in one file. These work on every platform, including web.
- `best` reaches higher resolutions by pairing a video only stream with a
  separate audio track. This needs the native backend, so on web it behaves
  like `high`.

Live videos always use the HLS playlist, regardless of the requested quality.

## Widget reference

`UniversalYoutubePlayer` takes either a `url` or a `controller`, never both.

| Property | Default | Description |
| --- | --- | --- |
| `url` | none | Link or video id to play (widget manages its own controller). |
| `controller` | none | A controller you own and dispose. |
| `autoPlay` | `true` | Start playing once the link resolves. |
| `quality` | `high` | Requested quality when using `url`. |
| `looping` | `false` | Repeat the video when it ends. |
| `aspectRatio` | `16 / 9` | Aspect ratio of the video surface. |
| `fit` | `BoxFit.contain` | How the video fills the surface. |
| `backgroundColor` | `Colors.black` | Color behind the video. |
| `controls` | `true` | Show the built in controls. |
| `placeholder` | none | Widget shown before playback begins. |
| `loadingBuilder` | none | Builder for the resolving state. |
| `errorBuilder` | none | Builder for the failure state. |

## Example app

The [`example`](example) folder has a full demo with a URL field, sample
videos, a scrub bar, transport buttons, a volume slider, and quality and speed
selectors. Run it on any platform:

```bash
cd example
flutter run -d macos     # or windows, linux, chrome, or a device
```

## Testing

Unit tests cover URL parsing and the value types and run with the analyzer:

```bash
flutter test
```

Playback touches the native backend and the network, so it is covered by
integration tests that run on a real device or desktop build:

```bash
cd example
flutter test integration_test -d macos
```

Swap `-d macos` for `windows`, `linux`, `chrome`, or a connected mobile device
to check that platform.

## How it works

1. The controller parses the link and fetches the video page with
   youtube_explode_dart. This gives it the title, author, and the list of
   available streams.
2. It picks a stream that matches the requested quality. For a live video it
   uses the HLS playlist instead.
3. It hands the stream URL to media_kit, which decodes and renders it through
   libmpv on desktop and mobile, and through the browser on web.

## Notes and limits

- Stream URLs come from parsing YouTube's own responses. YouTube can change
  those responses, which is why the resolver library is a normal dependency you
  can update. Pin and bump it as needed.
- This plays public videos. Age restricted or private videos, and anything that
  needs a signed in session, are out of scope.
- Respect YouTube's Terms of Service when you use this.

## License

MIT. See [LICENSE](LICENSE).
