/// The reason a load or playback attempt failed.
///
/// The controller inspects the underlying error and classifies it into one of
/// these so your UI can respond, for example by showing a country picker for
/// [geoRestricted] or a retry button for [botCheck] and [network].
enum YoutubePlayerErrorKind {
  /// The video was removed, made private, or never existed.
  unavailable,

  /// The video is not available in the current region.
  geoRestricted,

  /// The video requires a purchase or membership.
  requiresPurchase,

  /// YouTube refused the request as automated traffic. Common from VPN and
  /// datacenter IP addresses.
  botCheck,

  /// The video resolved but exposed no stream this platform can play.
  noStreams,

  /// A network problem prevented resolving or playing the video.
  network,

  /// The failure did not match any known category.
  unknown,
}

/// A classified failure raised while resolving or playing a YouTube video.
///
/// The controller stores the most recent one in
/// `UniversalYoutubeController.error` and throws it from `load`.
class YoutubePlayerException implements Exception {
  /// Creates a classified exception.
  const YoutubePlayerException(
    this.kind,
    this.message, {
    this.videoId,
    this.cause,
  });

  /// The category of the failure.
  final YoutubePlayerErrorKind kind;

  /// A short, human readable description of what went wrong.
  final String message;

  /// The id of the video that failed, when known.
  final String? videoId;

  /// The original error this was classified from, for logging.
  final Object? cause;

  /// Whether trying again might succeed without any change from the user.
  ///
  /// True for [YoutubePlayerErrorKind.botCheck] and
  /// [YoutubePlayerErrorKind.network], which are often transient.
  bool get isRetryable =>
      kind == YoutubePlayerErrorKind.botCheck ||
      kind == YoutubePlayerErrorKind.network;

  /// A suggestion you can surface to the user for this kind of failure.
  String get hint => switch (kind) {
    YoutubePlayerErrorKind.unavailable =>
      'This video was removed or made private.',
    YoutubePlayerErrorKind.geoRestricted =>
      'This video is blocked in the current region. Try a different network '
          'or location.',
    YoutubePlayerErrorKind.requiresPurchase =>
      'This video requires a purchase or membership.',
    YoutubePlayerErrorKind.botCheck =>
      'YouTube blocked this request as automated traffic. This is common on '
          'VPNs and datacenter IPs. Try a residential connection or retry.',
    YoutubePlayerErrorKind.noStreams =>
      'No playable stream was available for this video.',
    YoutubePlayerErrorKind.network =>
      'A network error occurred. Check the connection and retry.',
    YoutubePlayerErrorKind.unknown => 'The video could not be played.',
  };

  @override
  String toString() => 'YoutubePlayerException(${kind.name}): $message';
}
