import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/services/zoom_math.dart';

void main() {
  const Size viewport = Size(400, 225);
  const Offset center = Offset(200, 112.5);

  test('zoom stays between 1x and 4x', () {
    ZoomState state = ZoomMath.zoomAround(ZoomState.reset, 10, center, viewport);
    expect(state.scale, 4);
    state = ZoomMath.zoomAround(state, 0.01, center, viewport);
    expect(state, ZoomState.reset);
    expect(state.isZoomed, isFalse);
  });

  test('zooming around the centre does not move the picture', () {
    final ZoomState state = ZoomMath.zoomAround(
      ZoomState.reset,
      2,
      center,
      viewport,
    );
    expect(state.scale, 2);
    expect(state.dx, 0);
    expect(state.dy, 0);
  });

  test('zooming around a corner keeps that point under the fingers', () {
    final ZoomState state = ZoomMath.zoomAround(
      ZoomState.reset,
      2,
      const Offset(400, 225),
      viewport,
    );
    // The bottom-right corner stays at the bottom-right of the viewport.
    expect(state.dx, -200);
    expect(state.dy, -112.5);
  });

  test('pan cannot show the edge of the picture', () {
    ZoomState state = ZoomMath.zoomAround(ZoomState.reset, 2, center, viewport);
    state = ZoomMath.panBy(state, const Offset(5000, -5000), viewport);
    expect(state.dx, 200);
    expect(state.dy, -112.5);
  });

  test('pan does nothing while not zoomed', () {
    expect(
      ZoomMath.panBy(ZoomState.reset, const Offset(30, 30), viewport),
      ZoomState.reset,
    );
  });

  test('zooming out re-centres so no edge shows', () {
    ZoomState state = ZoomMath.zoomAround(
      ZoomState.reset,
      4,
      const Offset(400, 225),
      viewport,
    );
    state = ZoomMath.zoomAround(state, 0.5, center, viewport);
    expect(state.scale, 2);
    expect(state.dx.abs(), lessThanOrEqualTo(200));
  });

  test('buttons step through the range', () {
    ZoomState state = ZoomMath.step(ZoomState.reset, 1, viewport);
    expect(state.scale, 1.75);
    state = ZoomMath.step(state, -10, viewport);
    expect(state, ZoomState.reset);
    expect(ZoomMath.step(state, 10, viewport).scale, 4);
  });

  test('level labels drop a trailing zero', () {
    expect(ZoomMath.levelLabel(1), '1');
    expect(ZoomMath.levelLabel(2.5), '2.5');
    expect(ZoomMath.levelLabel(3.04), '3');
  });

  test('a swipe switches camera past a fifth of the width', () {
    expect(ZoomMath.isSwitchSwipe(-90, 400), isTrue);
    expect(ZoomMath.isSwitchSwipe(60, 400), isFalse);
    expect(ZoomMath.isSwitchSwipe(10, 0), isFalse);
  });
}
