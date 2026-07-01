/// Preferred video quality when resolving a YouTube stream.
///
/// YouTube exposes many stream variants for a single video. The controller
/// picks the muxed (video + audio combined) stream that best matches the
/// requested quality, falling back to the closest available option.
enum YoutubeVideoQuality {
  /// Lowest available resolution — best for constrained bandwidth.
  low,

  /// A balanced, widely-available resolution (typically 360p–480p muxed).
  medium,

  /// Highest available muxed resolution.
  high,

  /// Highest resolution available, combining a video-only stream with a
  /// separate audio track when no high-resolution muxed stream exists.
  ///
  /// Requires the underlying player to support an external audio track
  /// (libmpv / media_kit does). Falls back to [high] when unsupported.
  best,
}
