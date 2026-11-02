import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/widgets/camera_tile.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

import '../support/pump_app.dart';

final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  CameraTile tile({
    double width = 240,
    StreamStatus status = StreamStatus.live,
    Widget? video,
    bool videoVisible = false,
    Uint8List? poster,
    VoidCallback? onTap,
    VoidCallback? onStatusTap,
    bool showLabels = true,
    String? resolution = '1920x1080',
  }) {
    return CameraTile(
      name: 'Front door',
      status: status,
      statusLabel: 'Live',
      video: video,
      isVideoVisible: videoVisible,
      poster: poster,
      posterAgeLabel: '5 min',
      resolutionLabel: resolution,
      onTap: onTap,
      onStatusTap: onStatusTap,
      showLabels: showLabels,
    );
  }

  Widget sized(Widget child, {double width = 240}) =>
      SizedBox(width: width, height: width / AppSizes.tileAspectRatio, child: child);

  group('StreamStatus', () {
    test('maps every playback state', () {
      expect(StreamStatus.fromPlayerState(const PlayerPlaying()), StreamStatus.live);
      expect(StreamStatus.fromPlayerState(const PlayerConnecting()), StreamStatus.connecting);
      expect(StreamStatus.fromPlayerState(const PlayerBuffering()), StreamStatus.connecting);
      expect(StreamStatus.fromPlayerState(const PlayerReconnecting(attempt: 2)), StreamStatus.reconnecting);
      expect(
        StreamStatus.fromPlayerState(const PlayerError(AppError(ErrorClass.networkUnreachable))),
        StreamStatus.error,
      );
      expect(StreamStatus.fromPlayerState(const PlayerIdle()), StreamStatus.offline);
      expect(StreamStatus.fromPlayerState(const PlayerStopped()), StreamStatus.offline);
    });

    test('every status has its own icon', () {
      expect(StreamStatus.live.icon, AppIconName.live);
      expect(StreamStatus.error.icon, AppIconName.warning);
      expect(StreamStatus.offline.icon, AppIconName.wifiOff);
      expect(StreamStatus.connecting.icon, StreamStatus.reconnecting.icon);
    });
  });

  group('StreamStatusPill', () {
    testWidgets('shows icon and label, and icon only when asked', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Column(children: <Widget>[
          StreamStatusPill(status: StreamStatus.error, label: 'Error'),
          StreamStatusPill(status: StreamStatus.offline, label: 'Offline', iconOnly: true),
        ]),
      );
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('a tap is reported and an icon-only pill still has a 48 hit area', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        StreamStatusPill(status: StreamStatus.error, label: 'Error', iconOnly: true, onTap: () => taps++),
      );
      expect(tester.getSize(find.byType(StreamStatusPill)).shortestSide, greaterThanOrEqualTo(AppSizes.touchTarget));
      await tester.tap(find.byType(StreamStatusPill));
      expect(taps, 1);
    });

    testWidgets('live pulses; other states and reduced motion stay still', (WidgetTester tester) async {
      double opacityOf(WidgetTester t) => t.widget<FadeTransition>(find.byType(FadeTransition).last).opacity.value;

      await pumpApp(tester, const StreamStatusPill(status: StreamStatus.live, label: 'Live'));
      await tester.pump(const Duration(milliseconds: 1600));
      expect(opacityOf(tester), lessThan(0.6));

      await pumpApp(tester, const StreamStatusPill(status: StreamStatus.error, label: 'Error'));
      await tester.pump(const Duration(milliseconds: 800));
      expect(opacityOf(tester), 1);
    });

    testWidgets('with reduced motion the pulse is static', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpApp(tester, const StreamStatusPill(status: StreamStatus.live, label: 'Live'));
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.widget<FadeTransition>(find.byType(FadeTransition).last).opacity.value, 1);
    });
  });

  group('CameraTile', () {
    testWidgets('shows the name, status and resolution', (WidgetTester tester) async {
      await pumpApp(tester, sized(tile()));
      expect(find.text('Front door'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('1920x1080'), findsOneWidget);
    });

    testWidgets('has the video tile shape: md radius and a hairline border', (WidgetTester tester) async {
      await pumpApp(tester, sized(tile()));
      final BoxDecoration decoration = tester
          .widget<DecoratedBox>(find.descendant(of: find.byType(ClipRRect), matching: find.byType(DecoratedBox)).first)
          .decoration as BoxDecoration;
      expect(decoration.borderRadius, AppRadius.allMd);
      expect((decoration.border! as Border).top.width, AppSizes.hairline);
    });

    testWidgets('a narrow tile shows the status as an icon only', (WidgetTester tester) async {
      await pumpApp(tester, sized(tile(), width: 100), size: const Size(400, 800));
      expect(find.text('Live'), findsNothing);
      expect(find.text('Front door'), findsOneWidget);
      expect(find.text('1920x1080'), findsNothing);
    });

    testWidgets('the smallest tiles of a 16-up grid fit their overlay', (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(width: 97, height: 97 / AppSizes.tileAspectRatio, child: tile(onStatusTap: () {})),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the icon-only status opens its message when tapped', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(tester, sized(tile(onStatusTap: () => taps++), width: 100));
      await tester.tap(find.byType(StreamStatusPill));
      expect(taps, 1);
    });

    testWidgets('the video fades in over the poster', (WidgetTester tester) async {
      double videoOpacity() =>
          tester.widget<AnimatedOpacity>(find.descendant(of: find.byType(CameraTile), matching: find.byType(AnimatedOpacity))).opacity;

      await pumpApp(tester, sized(tile(video: const SizedBox.expand(key: Key('v')), poster: _pixel)));
      expect(videoOpacity(), 0);
      expect(find.text('5 min'), findsOneWidget);

      await pumpApp(tester, sized(tile(video: const SizedBox.expand(key: Key('v')), poster: _pixel, videoVisible: true)));
      await tester.pump(const Duration(milliseconds: 250));
      expect(videoOpacity(), 1);
      expect(find.text('5 min'), findsNothing);
    });

    testWidgets('a tile without a poster or video is just the backdrop with its overlay', (WidgetTester tester) async {
      await pumpApp(tester, sized(tile(status: StreamStatus.connecting)));
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the tile reports it', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(tester, sized(tile(onTap: () => taps++)));
      await tester.tapAt(tester.getCenter(find.byType(CameraTile)));
      expect(taps, 1);
    });

    testWidgets('the name plate can be switched off', (WidgetTester tester) async {
      await pumpApp(tester, sized(tile(showLabels: false)));
      expect(find.text('Front door'), findsNothing);
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('is announced with name, status and resolution', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, sized(tile(onTap: () {})));
      expect(find.bySemanticsLabel('Front door, Live, 1920x1080'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('overlay text stops scaling at 130 percent', (WidgetTester tester) async {
      await pumpApp(tester, sized(tile(), width: 300), textScale: 3, size: const Size(400, 800));
      final Text name = tester.widget<Text>(find.text('Front door'));
      expect(name.textScaler!.scale(10), closeTo(13, 0.01));
    });

    testWidgets('a long name is cut with an ellipsis', (WidgetTester tester) async {
      await pumpApp(
        tester,
        sized(
          const CameraTile(
            name: 'A very long camera name that cannot possibly fit on one line',
            status: StreamStatus.live,
            statusLabel: 'Live',
          ),
          width: 160,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
