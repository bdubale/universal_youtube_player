import 'package:flutter_test/flutter_test.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

void main() {
  group('YoutubePlayerException', () {
    test('carries its kind, message, and cause', () {
      final cause = StateError('boom');
      final e = YoutubePlayerException(
        YoutubePlayerErrorKind.botCheck,
        'blocked',
        videoId: 'dQw4w9WgXcQ',
        cause: cause,
      );
      expect(e.kind, YoutubePlayerErrorKind.botCheck);
      expect(e.message, 'blocked');
      expect(e.videoId, 'dQw4w9WgXcQ');
      expect(e.cause, same(cause));
    });

    test('marks bot check and network as retryable', () {
      for (final kind in [
        YoutubePlayerErrorKind.botCheck,
        YoutubePlayerErrorKind.network,
      ]) {
        expect(YoutubePlayerException(kind, '').isRetryable, isTrue);
      }
    });

    test('marks availability failures as not retryable', () {
      for (final kind in [
        YoutubePlayerErrorKind.unavailable,
        YoutubePlayerErrorKind.geoRestricted,
        YoutubePlayerErrorKind.requiresPurchase,
        YoutubePlayerErrorKind.noStreams,
      ]) {
        expect(YoutubePlayerException(kind, '').isRetryable, isFalse);
      }
    });

    test('provides a non-empty hint for every kind', () {
      for (final kind in YoutubePlayerErrorKind.values) {
        expect(YoutubePlayerException(kind, '').hint, isNotEmpty);
      }
    });

    test('names its kind in toString', () {
      final e = YoutubePlayerException(
        YoutubePlayerErrorKind.geoRestricted,
        'nope',
      );
      expect(e.toString(), contains('geoRestricted'));
      expect(e.toString(), contains('nope'));
    });
  });
}
