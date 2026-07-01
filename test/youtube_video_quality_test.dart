import 'package:flutter_test/flutter_test.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

void main() {
  group('YoutubeVideoQuality', () {
    test('lists the four supported levels', () {
      expect(YoutubeVideoQuality.values, [
        YoutubeVideoQuality.low,
        YoutubeVideoQuality.medium,
        YoutubeVideoQuality.high,
        YoutubeVideoQuality.best,
      ]);
    });

    test('exposes readable names for UI', () {
      expect(YoutubeVideoQuality.values.map((q) => q.name), [
        'low',
        'medium',
        'high',
        'best',
      ]);
    });
  });
}
