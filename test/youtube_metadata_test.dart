import 'package:flutter_test/flutter_test.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

void main() {
  group('YoutubeMetadata', () {
    const meta = YoutubeMetadata(
      videoId: 'dQw4w9WgXcQ',
      title: 'Never Gonna Give You Up',
      author: 'Rick Astley',
      isLive: false,
      duration: Duration(minutes: 3, seconds: 33),
      thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
    );

    test('exposes its fields', () {
      expect(meta.videoId, 'dQw4w9WgXcQ');
      expect(meta.title, 'Never Gonna Give You Up');
      expect(meta.author, 'Rick Astley');
      expect(meta.isLive, isFalse);
      expect(meta.duration, const Duration(minutes: 3, seconds: 33));
    });

    test('supports value equality', () {
      const same = YoutubeMetadata(
        videoId: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        author: 'Rick Astley',
        isLive: false,
        duration: Duration(minutes: 3, seconds: 33),
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );
      expect(meta, equals(same));
      expect(meta.hashCode, equals(same.hashCode));
    });

    test('differs when a field differs', () {
      const other = YoutubeMetadata(
        videoId: 'dQw4w9WgXcQ',
        title: 'A different title',
        author: 'Rick Astley',
        isLive: false,
      );
      expect(meta, isNot(equals(other)));
    });

    test('allows a null duration for live videos', () {
      const live = YoutubeMetadata(
        videoId: 'live0000000',
        title: 'Live stream',
        author: 'Someone',
        isLive: true,
      );
      expect(live.duration, isNull);
      expect(live.isLive, isTrue);
    });
  });
}
