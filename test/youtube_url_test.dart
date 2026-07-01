import 'package:flutter_test/flutter_test.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

void main() {
  const id = 'dQw4w9WgXcQ';

  group('extractYoutubeVideoId', () {
    final validCases = <String, String>{
      'watch url': 'https://www.youtube.com/watch?v=$id',
      'watch url with params': 'https://www.youtube.com/watch?v=$id&t=42s',
      'short url': 'https://youtu.be/$id',
      'short url with query': 'https://youtu.be/$id?t=42',
      'embed url': 'https://www.youtube.com/embed/$id',
      'shorts url': 'https://www.youtube.com/shorts/$id',
      'mobile url': 'https://m.youtube.com/watch?v=$id',
      'no scheme': 'youtube.com/watch?v=$id',
      'bare id': id,
      'surrounding whitespace': '  https://youtu.be/$id  ',
    };

    validCases.forEach((description, input) {
      test('parses $description', () {
        expect(extractYoutubeVideoId(input), id);
      });
    });

    final invalidCases = <String, String>{
      'empty string': '',
      'plain text': 'not a link',
      'other host': 'https://vimeo.com/123456',
      'too short id': 'abc',
    };

    invalidCases.forEach((description, input) {
      test('returns null for $description', () {
        expect(extractYoutubeVideoId(input), isNull);
      });
    });
  });

  group('isYoutubeVideoUrl', () {
    test('is true for a valid link', () {
      expect(isYoutubeVideoUrl('https://youtu.be/$id'), isTrue);
    });

    test('is false for an invalid link', () {
      expect(isYoutubeVideoUrl('https://example.com'), isFalse);
    });
  });
}
