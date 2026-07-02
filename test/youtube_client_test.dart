import 'package:flutter_test/flutter_test.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

void main() {
  group('YoutubeClient', () {
    test('exposes the selectable clients', () {
      expect(
        YoutubeClient.values,
        containsAll([
          YoutubeClient.tv,
          YoutubeClient.ios,
          YoutubeClient.android,
          YoutubeClient.androidVr,
          YoutubeClient.mediaConnect,
          YoutubeClient.web,
        ]),
      );
    });
  });

  group('defaultYoutubeClients', () {
    test('tries more than one client for resilience', () {
      expect(defaultYoutubeClients.length, greaterThan(1));
    });

    test('has no duplicates', () {
      expect(
        defaultYoutubeClients.toSet().length,
        defaultYoutubeClients.length,
      );
    });

    test('leads with a bot-check resilient client', () {
      expect(defaultYoutubeClients.first, YoutubeClient.ios);
    });
  });
}
