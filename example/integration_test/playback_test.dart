import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_youtube_player/universal_youtube_player.dart';

/// End to end playback tests.
///
/// These run on a real device or desktop build, so they exercise the native
/// backend and the network. Run them on each platform you support:
///
/// ```
/// cd example
/// flutter test integration_test -d macos
/// flutter test integration_test -d windows
/// flutter test integration_test -d linux
/// flutter test integration_test -d chrome
/// flutter test integration_test          # a connected Android or iOS device
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  UniversalYoutubePlayerBootstrap.ensureInitialized();

  const sampleUrl = 'https://www.youtube.com/watch?v=aqz-KE-bpKQ';

  Future<UniversalYoutubeController> loadAndWait(
    WidgetTester tester,
    String url, {
    bool autoPlay = true,
  }) async {
    final controller = UniversalYoutubeController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UniversalYoutubePlayer(controller: controller)),
      ),
    );

    await controller.load(url, autoPlay: autoPlay);

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (controller.status != YoutubePlayerStatus.ready &&
        DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    return controller;
  }

  testWidgets('resolves a link and reaches the ready state', (tester) async {
    final controller = await loadAndWait(tester, sampleUrl);

    expect(controller.status, YoutubePlayerStatus.ready);
    expect(controller.error, isNull);
    expect(controller.metadata, isNotNull);
    expect(controller.metadata!.videoId, isNotEmpty);
  });

  testWidgets('advances the playback position', (tester) async {
    final controller = await loadAndWait(tester, sampleUrl);
    expect(controller.status, YoutubePlayerStatus.ready);

    final start = controller.position;
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (controller.position <= start && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(controller.position, greaterThan(start));
  });

  testWidgets('pauses and resumes', (tester) async {
    final controller = await loadAndWait(tester, sampleUrl);

    await controller.pause();
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.isPlaying, isFalse);

    await controller.play();
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.isPlaying, isTrue);
  });

  testWidgets('mutes and restores the volume', (tester) async {
    final controller = await loadAndWait(tester, sampleUrl);

    await controller.setVolume(80);
    await controller.setMuted(true);
    expect(controller.isMuted, isTrue);
    expect(controller.volume, 0);

    await controller.setMuted(false);
    expect(controller.isMuted, isFalse);
    expect(controller.volume, closeTo(80, 0.01));
  });

  testWidgets('rejects an invalid link', (tester) async {
    final controller = UniversalYoutubeController();
    addTearDown(controller.dispose);

    expect(
      () => controller.load('this is not a youtube link'),
      throwsArgumentError,
    );
  });
}
