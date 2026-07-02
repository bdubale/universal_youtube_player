/// A YouTube client that the resolver can impersonate when fetching streams.
///
/// YouTube serves its internal API to several official apps, and each one is
/// treated differently by YouTube's abuse checks. When one client is refused
/// (for example from a VPN or datacenter IP), another often still works, so
/// the controller tries a list of them in order and keeps whatever resolves.
///
/// See [defaultYoutubeClients] for the list used when you do not choose one.
enum YoutubeClient {
  /// The living-room and smart-TV client. Reliable for many restricted videos.
  tv,

  /// The iOS app client. Broadly reliable and rarely challenged.
  ios,

  /// The Android app client.
  android,

  /// The Android VR client. Useful because it avoids some newer checks.
  androidVr,

  /// The client used by cast and media-connect surfaces.
  mediaConnect,

  /// A desktop web browser client.
  web,
}

/// The clients tried, in order, when a caller does not pass their own list.
///
/// Ordered for resilience against bot checks rather than for speed: the iOS
/// and Android VR clients tend to pass challenges that block the default web
/// path, and the TV client covers many age or region restricted videos.
const List<YoutubeClient> defaultYoutubeClients = <YoutubeClient>[
  YoutubeClient.ios,
  YoutubeClient.androidVr,
  YoutubeClient.tv,
];
