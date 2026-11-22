import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Turns a player session's `viewHandle` into a widget.
///
/// Engine sessions (RTSP) hand out a media_kit `VideoController`. The Dart
/// MJPEG session hands out a `ValueListenable<Uint8List?>` of the newest JPEG.
/// Anything else, or a MJPEG stream that has not produced a frame yet, draws
/// the backdrop alone. Screens reach this through `AppProviders.videoBuilder`
/// because they may not import `platform/`.
Widget buildVideoSurface(
  Object? handle, {
  BoxFit fit = BoxFit.cover,
  Color backdrop = const Color(0xFF050608),
}) {
  if (handle is VideoController) {
    return Video(
      controller: handle,
      controls: null,
      fit: fit,
      fill: backdrop,
      wakelock: false,
    );
  }
  if (handle is ValueListenable<Uint8List?>) {
    return ColoredBox(
      color: backdrop,
      child: ValueListenableBuilder<Uint8List?>(
        valueListenable: handle,
        builder: (BuildContext context, Uint8List? frame, Widget? _) {
          if (frame == null) {
            return const SizedBox.expand();
          }
          return SizedBox.expand(
            child: Image.memory(
              frame,
              fit: fit,
              gaplessPlayback: true,
              excludeFromSemantics: true,
            ),
          );
        },
      ),
    );
  }
  return ColoredBox(color: backdrop, child: const SizedBox.expand());
}
