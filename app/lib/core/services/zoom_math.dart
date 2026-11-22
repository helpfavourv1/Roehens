import 'dart:ui';

import 'package:roehens/core/constants/limits.dart';

/// Digital zoom of the fullscreen picture: a scale from 1 to 4 and a pan that
/// never shows the edge of the picture.
class ZoomState {
  const ZoomState({this.scale = Limits.minZoom, this.dx = 0, this.dy = 0});

  static const ZoomState reset = ZoomState();

  final double scale;

  /// Pan in logical pixels, positive to the right and down.
  final double dx;
  final double dy;

  bool get isZoomed => scale > Limits.minZoom + 0.01;

  @override
  bool operator ==(Object other) {
    return other is ZoomState &&
        other.scale == scale &&
        other.dx == dx &&
        other.dy == dy;
  }

  @override
  int get hashCode => Object.hash(scale, dx, dy);
}

class ZoomMath {
  ZoomMath._();

  /// Zooms by [factor] around [focal] (a point in the viewport), keeping the
  /// point under the fingers where it is.
  static ZoomState zoomAround(
    ZoomState from,
    double factor,
    Offset focal,
    Size viewport,
  ) {
    final double scale = (from.scale * factor).clamp(
      Limits.minZoom,
      Limits.maxZoom,
    );
    final double ratio = scale / from.scale;
    final Offset center = Offset(viewport.width / 2, viewport.height / 2);
    final Offset toFocal = focal - center;
    // The picture point under the focal point stays put.
    final double dx = toFocal.dx - (toFocal.dx - from.dx) * ratio;
    final double dy = toFocal.dy - (toFocal.dy - from.dy) * ratio;
    return _bounded(ZoomState(scale: scale, dx: dx, dy: dy), viewport);
  }

  /// Moves the picture by [delta]; only possible while zoomed.
  static ZoomState panBy(ZoomState from, Offset delta, Size viewport) {
    if (!from.isZoomed) {
      return ZoomState.reset;
    }
    return _bounded(
      ZoomState(
        scale: from.scale,
        dx: from.dx + delta.dx,
        dy: from.dy + delta.dy,
      ),
      viewport,
    );
  }

  /// A step for the zoom buttons: [steps] of one quarter of the range.
  static ZoomState step(ZoomState from, int steps, Size viewport) {
    final double target = from.scale + steps * (Limits.maxZoom - 1) / 4;
    return zoomAround(
      from,
      target.clamp(Limits.minZoom, Limits.maxZoom) / from.scale,
      Offset(viewport.width / 2, viewport.height / 2),
      viewport,
    );
  }

  static ZoomState _bounded(ZoomState state, Size viewport) {
    if (state.scale <= Limits.minZoom) {
      return ZoomState.reset;
    }
    final double maxX = viewport.width * (state.scale - 1) / 2;
    final double maxY = viewport.height * (state.scale - 1) / 2;
    return ZoomState(
      scale: state.scale,
      dx: state.dx.clamp(-maxX, maxX),
      dy: state.dy.clamp(-maxY, maxY),
    );
  }

  /// "2.5" for display next to the multiplication sign.
  static String levelLabel(double scale) {
    final double rounded = (scale * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1);
  }

  /// Distance of a swipe, as a fraction of the width, that switches camera.
  static bool isSwitchSwipe(double dx, double width, {double fraction = 0.2}) {
    return width > 0 && dx.abs() >= width * fraction;
  }
}
