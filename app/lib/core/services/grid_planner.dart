import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/stream_profile.dart';
import 'package:roehens/core/models/stream_protocol.dart';

/// Whether a tile plays video or shows its last still image.
enum TileMode { live, poster }

/// The decision for one tile.
class TilePlan {
  const TilePlan({
    required this.cameraId,
    required this.mode,
    required this.streamKind,
    required this.refreshPoster,
  });

  final String cameraId;
  final TileMode mode;

  /// Which stream to use: the substream in the grid, the main stream when the
  /// tile is focused in fullscreen.
  final StreamKind streamKind;

  /// A poster tile keeps its still fresh by fetching a snapshot every few
  /// seconds. Only HTTP cameras can; RTSP posters stay static.
  final bool refreshPoster;

  @override
  bool operator ==(Object other) {
    return other is TilePlan &&
        other.cameraId == cameraId &&
        other.mode == mode &&
        other.streamKind == streamKind &&
        other.refreshPoster == refreshPoster;
  }

  @override
  int get hashCode => Object.hash(cameraId, mode, streamKind, refreshPoster);
}

/// The plan for every visible tile, in the order they were given.
class GridPlan {
  const GridPlan(this.tiles);

  final List<TilePlan> tiles;

  int get liveCount {
    return tiles.where((TilePlan t) => t.mode == TileMode.live).length;
  }

  TilePlan? planFor(String cameraId) {
    for (final TilePlan tile in tiles) {
      if (tile.cameraId == cameraId) {
        return tile;
      }
    }
    return null;
  }
}

/// Decides which tiles decode (specification D3). Pure: same input, same plan.
///
/// The focused tile always plays. Other tiles play in screen order until the
/// decoder budget is used; the rest become posters. Under memory pressure only
/// the focused tile plays, or half the budget when nothing is focused.
class GridPlanner {
  const GridPlanner();

  /// Decoder cost of a protocol. A snapshot camera is polled, not decoded.
  static int decoderCost(StreamProtocol protocol) {
    return switch (protocol) {
      StreamProtocol.rtsp => 1,
      StreamProtocol.mjpeg => 1,
      StreamProtocol.httpSnapshot => 0,
    };
  }

  static int budgetFor({required bool isTablet}) {
    return isTablet ? Limits.tabletDecoderBudget : Limits.phoneDecoderBudget;
  }

  GridPlan plan({
    required List<Camera> visible,
    required int decoderBudget,
    String? focusedId,
    bool lowMemory = false,
    bool preferSubstream = true,
  }) {
    final bool hasFocus =
        focusedId != null && visible.any((Camera c) => c.id == focusedId);
    final int budget = lowMemory
        ? (decoderBudget ~/ 2 < 1 ? 1 : decoderBudget ~/ 2)
        : decoderBudget;

    // Priority: the focused tile first, then screen order.
    final List<Camera> ordered = <Camera>[
      if (hasFocus) visible.firstWhere((Camera c) => c.id == focusedId),
      for (final Camera c in visible)
        if (!hasFocus || c.id != focusedId) c,
    ];

    final Map<String, TileMode> modes = <String, TileMode>{};
    int used = 0;
    for (final Camera camera in ordered) {
      final int cost = decoderCost(camera.protocol);
      final bool isFocused = hasFocus && camera.id == focusedId;
      if (isFocused) {
        modes[camera.id] = TileMode.live;
        used += cost;
      } else if (lowMemory && hasFocus) {
        modes[camera.id] = TileMode.poster;
      } else if (cost == 0) {
        modes[camera.id] = TileMode.live;
      } else if (used + cost <= budget) {
        modes[camera.id] = TileMode.live;
        used += cost;
      } else {
        modes[camera.id] = TileMode.poster;
      }
    }

    return GridPlan(<TilePlan>[
      for (final Camera camera in visible)
        TilePlan(
          cameraId: camera.id,
          mode: modes[camera.id]!,
          streamKind: _kindFor(camera, hasFocus && camera.id == focusedId, preferSubstream),
          refreshPoster:
              modes[camera.id] == TileMode.poster &&
              camera.protocol != StreamProtocol.rtsp,
        ),
    ]);
  }

  StreamKind _kindFor(Camera camera, bool isFocused, bool preferSubstream) {
    if (isFocused) {
      return StreamKind.main;
    }
    return preferSubstream && camera.hasSubstream
        ? StreamKind.sub
        : StreamKind.main;
  }
}
