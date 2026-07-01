import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Extracts the eleven character video id from a YouTube link or a bare id.
///
/// Recognises the common link shapes, including:
///
/// * `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
/// * `https://youtu.be/dQw4w9WgXcQ`
/// * `https://www.youtube.com/embed/dQw4w9WgXcQ`
/// * `https://www.youtube.com/shorts/dQw4w9WgXcQ`
/// * `dQw4w9WgXcQ` (an id on its own)
///
/// Surrounding whitespace is ignored. Returns the id, or `null` when [input]
/// does not contain a valid YouTube video id.
String? extractYoutubeVideoId(String input) =>
    VideoId.parseVideoId(input.trim());

/// Whether [input] contains a recognisable YouTube video id.
bool isYoutubeVideoUrl(String input) => extractYoutubeVideoId(input) != null;
