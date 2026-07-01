/// Requested video quality when resolving a YouTube link.
///
/// YouTube publishes each video in several separate streams. The controller
/// maps the value you request to the closest available stream and falls back
/// gracefully when an exact match is not offered.
enum YoutubeVideoQuality {
  /// The lowest available resolution. Useful on metered or slow connections.
  low,

  /// A middle resolution, typically around 360p to 480p.
  medium,

  /// The highest resolution available as a single combined stream.
  high,

  /// The highest resolution available overall.
  ///
  /// On desktop and mobile this pairs a video-only stream with a separate
  /// audio track to reach resolutions above 720p. On the web, where a single
  /// source URL is required, it behaves like [high].
  best,
}
