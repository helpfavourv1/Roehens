import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/app/live_sessions.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/providers/cameras_provider.dart';
import 'package:roehens/core/providers/layout_provider.dart';
import 'package:roehens/core/providers/settings_provider.dart';
import 'package:roehens/core/services/camera_repository.dart';
import 'package:roehens/core/services/grid_planner.dart';
import 'package:roehens/platform/player/frame_capture_service.dart';
import 'package:roehens/platform/player/player_pool.dart';

import '../support/async_helpers.dart';
import '../support/fake_player.dart';
import '../support/fakes.dart';
import '../support/live_fakes.dart';

void main() {
  late FakeStorage storage;
  late FakeKeyValueStore store;
  late List<FakePlayerSession> sessions;
  late PlayerPool pool;
  late CamerasProvider cameras;
  late LayoutProvider layout;
  late SettingsProvider settings;
  late LiveSessions live;

  Future<void> boot(List<Camera> saved, {int pageSize = 4}) async {
    storage = FakeStorage();
    store = FakeKeyValueStore();
    sessions = <FakePlayerSession>[];
    for (final Camera c in saved) {
      storage.cameras[c.id] = c;
    }
    final FakeLogger logger = FakeLogger();
    final CameraRepository repository = CameraRepository(
      storage: storage,
      vault: FakeVault(),
      clock: FakeClock(),
    );
    pool = PlayerPool(
      sessionFactory: (_) {
        final FakePlayerSession s = FakePlayerSession()..frame = Uint8List(4);
        sessions.add(s);
        return s;
      },
      startStagger: Duration.zero,
    );
    cameras = CamerasProvider(repository: repository);
    layout = LayoutProvider(storage: storage, store: store, logger: logger);
    settings = SettingsProvider(store: store, logger: logger);
    await cameras.load();
    await layout.load();
    await layout.setPageSize(pageSize, cameraCount: saved.length);
    await layout.syncCameras(cameras.value.cameras);
    live = LiveSessions(
      pool: pool,
      planner: const GridPlanner(),
      cameras: cameras,
      layout: layout,
      settings: settings,
      repository: repository,
      snapshots: FrameCaptureService(pool: pool),
      logger: logger,
    );
  }

  tearDown(() async {
    live.dispose();
    await pool.disposeAll();
  });

  List<Camera> five() => <Camera>[
    for (int i = 0; i < 5; i++)
      cameraWithSub(id: 'c$i', name: 'Cam $i', sortIndex: i),
  ];

  test(
    'the grid decodes only the cameras on the page, on the substream',
    () async {
      await boot(five());
      live.setViewingGrid(viewing: true);
      await waitUntil(() => pool.keys.length == 4);

      expect(pool.keys.toSet(), <String>{'c0', 'c1', 'c2', 'c3'});
      expect(live.sessionFor('c4'), isNull);
      for (final FakePlayerSession s in sessions) {
        expect(s.opened.single.uri.path, '/sub');
      }
    },
  );

  test('turning the page swaps the cameras that decode', () async {
    await boot(five());
    live.setViewingGrid(viewing: true);
    await waitUntil(() => pool.keys.length == 4);

    layout.setPage(1, cameraCount: 5);
    await waitUntil(() => pool.keys.toSet().contains('c4'));
    expect(pool.keys.toSet(), <String>{'c4'});
  });

  test('more tiles than decoders: the rest wait as posters', () async {
    final List<Camera> six = <Camera>[
      for (int i = 0; i < 6; i++)
        cameraWithSub(id: 'c$i', name: 'Cam $i', sortIndex: i),
    ];
    await boot(six, pageSize: 6);
    live.setViewingGrid(viewing: true);
    await waitUntil(() => pool.keys.length == Limits.phoneDecoderBudget);

    expect(live.plan.liveCount, Limits.phoneDecoderBudget);
    expect(live.plan.tiles.length, 6);
  });

  test('a tablet may decode more', () async {
    final List<Camera> six = <Camera>[
      for (int i = 0; i < 6; i++)
        cameraWithSub(id: 'c$i', name: 'Cam $i', sortIndex: i),
    ];
    await boot(six, pageSize: 6);
    live.setViewingGrid(viewing: true, isTablet: true);
    await waitUntil(() => pool.keys.length == 6);
  });

  test(
    'fullscreen plays one camera: substream first, then the main stream',
    () async {
      await boot(five());
      live.setViewingGrid(viewing: true);
      await waitUntil(() => pool.keys.length == 4);

      live.focus('c2');
      await waitUntil(() => pool.keys.length == 1 && pool.keys.first == 'c2');
      expect(live.focusIsMainStream, isFalse);
      expect(pool.sessionFor('c2')!.source.uri.path, '/sub');

      await waitUntil(() => live.focusIsMainStream);
      await waitUntil(() => pool.sessionFor('c2')?.source.uri.path == '/main');

      live.focus(null);
      await waitUntil(() => pool.keys.length == 4);
    },
  );

  test('low quality keeps the substream in fullscreen', () async {
    await boot(five());
    live.focus('c1', lowQuality: true);
    await waitUntil(() => pool.sessionFor('c1') != null);
    await Future<void>.delayed(
      Limits.mainStreamSettle + const Duration(milliseconds: 200),
    );
    expect(pool.sessionFor('c1')!.source.uri.path, '/sub');

    live.setLowQuality(lowQuality: false);
    await waitUntil(() => pool.sessionFor('c1')?.source.uri.path == '/main');
  });

  test(
    'leaving the app disposes every player; returning restores them',
    () async {
      await boot(five());
      live.setViewingGrid(viewing: true);
      await waitUntil(() => pool.keys.length == 4);

      live.setForeground(foreground: false);
      await waitUntil(() => pool.keys.isEmpty);
      expect(sessions.where((FakePlayerSession s) => s.disposed).length, 4);

      live.setForeground(foreground: true);
      await waitUntil(() => pool.keys.length == 4);
    },
  );

  test('a playing tile that stops keeps its last picture', () async {
    await boot(five());
    live.setViewingGrid(viewing: true);
    await waitUntil(() => pool.keys.length == 4);
    for (final FakePlayerSession s in sessions) {
      s.emit(const PlayerPlaying());
    }
    await waitUntil(
      () => pool.keys.every(
        (String k) => pool.sessionFor(k)!.state.value is PlayerPlaying,
      ),
    );

    layout.setPage(1, cameraCount: 5);
    await waitUntil(() => pool.keys.toSet().contains('c4'));

    expect(live.posterFor('c0'), isNotNull);
    expect(live.posterFor('c0')!.bytes, isNotEmpty);
    expect(live.posterFor('c4'), isNull);
  });

  test('the screen sees state through LiveSession, not the pool', () async {
    await boot(five());
    live.setViewingGrid(viewing: true);
    await waitUntil(() => live.sessionFor('c0') != null);

    final LiveSession session = live.sessionFor('c0')!;
    expect(session.state.value, isA<PlayerConnecting>());
    expect(session.viewHandle, isNotNull);
    expect(session.videoSize.value, isNull);
  });

  test('mute follows the fullscreen camera across the stream switch', () async {
    await boot(five());
    live.focus('c1');
    await waitUntil(() => pool.sessionFor('c1') != null);
    await live.setMuted(muted: true);
    expect(live.isMuted, isTrue);
    expect(sessions.last.lastMuted, isTrue);

    await waitUntil(() => pool.sessionFor('c1')?.source.uri.path == '/main');
    await waitUntil(() => sessions.last.lastMuted == true);

    live.focus('c2');
    expect(live.isMuted, isFalse);
  });

  test('a deleted camera stops decoding', () async {
    await boot(five());
    live.setViewingGrid(viewing: true);
    await waitUntil(() => pool.keys.length == 4);

    await cameras.delete('c1');
    await waitUntil(() => !pool.keys.contains('c1'));
  });

  test('nothing decodes while the Live screen is not showing', () async {
    await boot(five());
    live.setViewingGrid(viewing: false);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(pool.keys, isEmpty);
  });
}
