import 'package:flutter_test/flutter_test.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

// These unit tests cover pure logic only. Anything that constructs a
// controller/player exercises the native libmpv backend, which is unavailable
// under `flutter test` (no app bundle) — that path is verified by the example
// app instead.
void main() {
  group('UniversalYoutubePlayer widget arguments', () {
    test('rejects providing neither url nor controller', () {
      expect(UniversalYoutubePlayer.new, throwsAssertionError);
    });
  });

  group('YoutubeVideoQuality', () {
    test('exposes the documented options', () {
      expect(YoutubeVideoQuality.values, hasLength(4));
      expect(
        YoutubeVideoQuality.values.map((q) => q.name),
        containsAll(['low', 'medium', 'high', 'best']),
      );
    });
  });

  group('YoutubeMetadata', () {
    test('stores its fields', () {
      const meta = YoutubeMetadata(
        videoId: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        author: 'Rick Astley',
        isLive: false,
        duration: Duration(minutes: 3, seconds: 33),
      );
      expect(meta.videoId, 'dQw4w9WgXcQ');
      expect(meta.isLive, isFalse);
      expect(meta.duration, const Duration(minutes: 3, seconds: 33));
    });
  });
}
