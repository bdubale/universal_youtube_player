/// Details about a resolved YouTube video.
///
/// A controller populates this as soon as it fetches the video page, before
/// playback begins, so you can render a title or thumbnail while the stream
/// loads.
class YoutubeMetadata {
  /// Creates metadata for a single video.
  const YoutubeMetadata({
    required this.videoId,
    required this.title,
    required this.author,
    required this.isLive,
    this.duration,
    this.thumbnailUrl,
  });

  /// The eleven character YouTube video id, for example `dQw4w9WgXcQ`.
  final String videoId;

  /// The video title.
  final String title;

  /// The name of the channel that published the video.
  final String author;

  /// Whether the video is a live broadcast.
  final bool isLive;

  /// The total running time, or `null` for live broadcasts and videos whose
  /// length could not be determined.
  final Duration? duration;

  /// A URL for the video thumbnail, or `null` when none was reported.
  final String? thumbnailUrl;

  @override
  bool operator ==(Object other) =>
      other is YoutubeMetadata &&
      other.videoId == videoId &&
      other.title == title &&
      other.author == author &&
      other.isLive == isLive &&
      other.duration == duration &&
      other.thumbnailUrl == thumbnailUrl;

  @override
  int get hashCode =>
      Object.hash(videoId, title, author, isLive, duration, thumbnailUrl);

  @override
  String toString() =>
      'YoutubeMetadata(videoId: $videoId, title: $title, '
      'author: $author, isLive: $isLive, duration: $duration)';
}
