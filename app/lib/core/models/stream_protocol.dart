/// How a camera delivers video.
enum StreamProtocol {
  /// RTSP, over TCP or UDP.
  rtsp,

  /// Motion JPEG over HTTP (`multipart/x-mixed-replace`).
  mjpeg,

  /// Single JPEG images fetched repeatedly over HTTP.
  httpSnapshot,
}

/// Transport used for RTSP media.
enum StreamTransport { tcp, udp, auto }
