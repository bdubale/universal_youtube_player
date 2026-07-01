import 'package:flutter_test/flutter_test.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

void main() {
  group('UniversalYoutubePlayer', () {
    test('requires either a url or a controller', () {
      expect(UniversalYoutubePlayer.new, throwsAssertionError);
    });

    test('keeps its configuration defaults', () {
      const player = UniversalYoutubePlayer(
        url: 'https://youtu.be/dQw4w9WgXcQ',
      );
      expect(player.autoPlay, isTrue);
      expect(player.controls, isTrue);
      expect(player.looping, isFalse);
      expect(player.quality, YoutubeVideoQuality.high);
      expect(player.aspectRatio, 16 / 9);
    });
  });
}
