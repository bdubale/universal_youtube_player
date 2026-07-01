/// Lightweight metadata for a resolved YouTube video.
class YoutubeMetadata {
  const YoutubeMetadata({
    required this.videoId,
    required this.title,
    required this.author,
    required this.isLive,
    this.duration,
    this.thumbnailUrl,
  });

  /// The 11-character YouTube video id.
  final String videoId;

  /// Human-readable video title.
  final String title;

  /// Channel / uploader name.
  final String author;

  /// Whether this is a live broadcast.
  final bool isLive;

  /// Total duration, or `null` for live streams / when unknown.
  final Duration? duration;

  /// URL of a representative thumbnail, if available.
  final String? thumbnailUrl;

  @override
  String toString() =>
      'YoutubeMetadata(videoId: $videoId, title: $title, author: $author, '
      'isLive: $isLive, duration: $duration)';
}
