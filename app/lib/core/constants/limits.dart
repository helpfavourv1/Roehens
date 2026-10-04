/// Numeric limits and budgets from the specification. Everything that tunes
/// behavior lives here so one place changes when a device test says so.
class Limits {
  Limits._();

  // Reconnect (D3): 1s, 2s, 4s, 8s, then 15s cap, +-20% jitter.
  static const List<Duration> reconnectBackoff = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
  ];
  static const double reconnectJitter = 0.20;
  static const Duration reconnectHealthyReset = Duration(seconds: 30);
  static const int reconnectMaxAttempts = 10;

  // Concurrency (D3).
  static const int phoneDecoderBudget = 4;
  static const int tabletDecoderBudget = 8;
  static const Duration posterRefresh = Duration(seconds: 5);
  static const Duration mainStreamSettle = Duration(milliseconds: 400);
  static const Duration resumeStagger = Duration(milliseconds: 150);

  // Grid (A3).
  static const List<int> gridSizes = <int>[1, 2, 4, 6, 9, 12, 16];
  static const List<int> autoCycleSeconds = <int>[5, 10, 15, 30, 60];
  static const int defaultAutoCycleSeconds = 10;

  // Zoom (A3): digital zoom 1x to 4x.
  static const double minZoom = 1;
  static const double maxZoom = 4;

  // Discovery (D4).
  static const List<int> sweepPorts = <int>[80, 554, 8000, 8080, 8554];
  static const int sweepConcurrency = 48;
  static const Duration sweepConnectTimeout = Duration(milliseconds: 400);
  static const String wsDiscoveryAddress = '239.255.255.250';
  static const int wsDiscoveryPort = 3702;

  // Ports and text.
  static const int defaultRtspPort = 554;
  static const int defaultHttpPort = 80;
  static const int minPort = 1;
  static const int maxPort = 65535;
  static const int maxCameraNameLength = 64;

  // Remote flags (D7).
  static const Duration flagsTimeout = Duration(seconds: 4);
  static const Duration flagsRecheck = Duration(hours: 6);

  // Undo after delete (A3).
  static const Duration undoWindow = Duration(seconds: 8);

  // Local log ring buffer.
  static const int logRingSize = 500;
}
