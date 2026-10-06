import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/contracts/player_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/player_state.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/reconnect_policy.dart';
import 'package:roehens/platform/player/frame_capture_service.dart';
import 'package:roehens/platform/player/player_pool.dart';
import 'package:roehens/core/contracts/snapshot_contract.dart';
import 'package:roehens/core/errors/result.dart';

import '../../support/async_helpers.dart';
import '../../support/fake_player.dart';
import '../../support/fakes.dart';

PlayerSource source(String host, {StreamProtocol protocol = StreamProtocol.rtsp}) {
  return PlayerSource(uri: Uri.parse('rtsp://$host:554/s'), protocol: protocol);
}

const PlayerState dropped = PlayerError(AppError(ErrorClass.streamDropped));

void main() {
  late List<FakePlayerSession> created;

  PlayerPool makePool({
    Duration stagger = Duration.zero,
    ClockContract? clock,
    int maxAttempts = 3,
    void Function(FakePlayerSession session)? configure,
  }) {
    created = <FakePlayerSession>[];
    return PlayerPool(
      sessionFactory: (StreamProtocol protocol) {
        final FakePlayerSession session = FakePlayerSession();
        configure?.call(session);
        created.add(session);
        return session;
      },
      policyFactory: () => ReconnectPolicy(
        backoff: const <Duration>[Duration(milliseconds: 10)],
        jitter: 0,
        maxAttempts: maxAttempts,
      ),
      startStagger: stagger,
      clock: clock ?? FakeClock(),
    );
  }

  group('starting and stopping sessions', () {
    test('reconcile opens one session per wanted key', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{
        'a': source('a'),
        'b': source('b'),
      });
      expect(pool.keys.toSet(), <String>{'a', 'b'});
      expect(created.length, 2);
      expect(created[0].opened.single, source('a'));
      expect(pool.sessionFor('a')!.state.value, isA<PlayerConnecting>());
      await pool.disposeAll();
    });

    test('keys that are no longer wanted are disposed', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{
        'a': source('a'),
        'b': source('b'),
      });
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      expect(pool.keys.toSet(), <String>{'a'});
      expect(created[0].disposed, isFalse);
      expect(created[1].disposed, isTrue);
      await pool.disposeAll();
    });

    test('an unchanged source is not restarted', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      expect(created.length, 1);
      expect(created[0].opened.length, 1);
      await pool.disposeAll();
    });

    test('a changed source replaces the session', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{'a': source('old')});
      await pool.reconcile(<String, PlayerSource>{'a': source('new')});
      expect(created.length, 2);
      expect(created[0].disposed, isTrue);
      expect(created[1].opened.single, source('new'));
      await pool.disposeAll();
    });

    test('release disposes one session and stops wanting it', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{
        'a': source('a'),
        'b': source('b'),
      });
      await pool.release('a');
      expect(pool.keys.toSet(), <String>{'b'});
      expect(created[0].disposed, isTrue);
      await pool.disposeAll();
    });

    test('new sessions start one stagger apart', () async {
      final PlayerPool pool = makePool(stagger: const Duration(milliseconds: 40));
      final Stopwatch clock = Stopwatch()..start();
      await pool.reconcile(<String, PlayerSource>{
        'a': source('a'),
        'b': source('b'),
        'c': source('c'),
      });
      expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(75));
      expect(created.length, 3);
      await pool.disposeAll();
    });

    test('disposeAll disposes every session', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{
        'a': source('a'),
        'b': source('b'),
      });
      await pool.disposeAll();
      expect(pool.keys, isEmpty);
      expect(created.every((FakePlayerSession s) => s.disposed), isTrue);
    });

    test('a session that cannot be opened ends in an error, not a crash', () async {
      final PlayerPool pool = makePool(
        configure: (FakePlayerSession s) => s.openError = StateError('boom'),
      );
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      final PlayerState state = pool.sessionFor('a')!.state.value;
      expect(state, isA<PlayerError>());
      expect((state as PlayerError).error.errorClass, ErrorClass.fatal);
      await pool.disposeAll();
    });
  });

  group('reconnecting', () {
    test('a dropped stream reconnects and returns to playing', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      final PooledSession pooled = pool.sessionFor('a')!;
      final FakePlayerSession session = created.single;

      session.emit(const PlayerPlaying());
      expect(pooled.state.value, isA<PlayerPlaying>());

      session.emit(dropped);
      expect(pooled.state.value, const PlayerReconnecting(attempt: 1));

      await waitUntil(() => session.opened.length == 2);
      session.emit(const PlayerPlaying());
      expect(pooled.state.value, isA<PlayerPlaying>());
      await pool.disposeAll();
    });

    test('the tile keeps saying reconnecting while the engine reconnects', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      final FakePlayerSession session = created.single;
      session.emit(dropped);
      await waitUntil(() => session.opened.length == 2);
      // open() put the session in "connecting"; the tile still shows reconnecting.
      expect(
        pool.sessionFor('a')!.state.value,
        const PlayerReconnecting(attempt: 1),
      );
      await pool.disposeAll();
    });

    test('an error that retrying cannot fix is shown and not retried', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      final FakePlayerSession session = created.single;

      session.emit(const PlayerError(AppError(ErrorClass.authFailed)));
      final PlayerState state = pool.sessionFor('a')!.state.value;
      expect((state as PlayerError).error.errorClass, ErrorClass.authFailed);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(session.opened.length, 1);
      await pool.disposeAll();
    });

    test('after the attempts run out the tile waits for a manual retry', () async {
      final PlayerPool pool = makePool(maxAttempts: 2);
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      final FakePlayerSession session = created.single;
      final PooledSession pooled = pool.sessionFor('a')!;

      session.emit(dropped);
      await waitUntil(() => session.opened.length == 2);
      session.emit(dropped);
      await waitUntil(() => session.opened.length == 3);
      session.emit(dropped);

      expect(pooled.state.value, isA<PlayerError>());
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(session.opened.length, 3);

      await pool.retry('a');
      expect(session.opened.length, 4);
      expect(pooled.state.value, isA<PlayerConnecting>());
      session.emit(dropped);
      expect(pooled.state.value, const PlayerReconnecting(attempt: 1));
      await pool.disposeAll();
    });

    test('long healthy playback forgives earlier failures', () async {
      final FakeClock clock = FakeClock();
      final PlayerPool pool = makePool(clock: clock, maxAttempts: 5);
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      final FakePlayerSession session = created.single;
      final PooledSession pooled = pool.sessionFor('a')!;

      session.emit(dropped);
      expect(pooled.state.value, const PlayerReconnecting(attempt: 1));
      await waitUntil(() => session.opened.length == 2);

      session.emit(const PlayerPlaying());
      clock.advance(const Duration(seconds: 31));
      session.emit(dropped);
      expect(pooled.state.value, const PlayerReconnecting(attempt: 1));
      await pool.disposeAll();
    });

    test('a short healthy spell does not forgive failures', () async {
      final FakeClock clock = FakeClock();
      final PlayerPool pool = makePool(clock: clock, maxAttempts: 5);
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      final FakePlayerSession session = created.single;
      final PooledSession pooled = pool.sessionFor('a')!;

      session.emit(dropped);
      await waitUntil(() => session.opened.length == 2);
      session.emit(const PlayerPlaying());
      clock.advance(const Duration(seconds: 5));
      session.emit(dropped);
      expect(pooled.state.value, const PlayerReconnecting(attempt: 2));
      await pool.disposeAll();
    });
  });

  group('app lifecycle', () {
    test('pause disposes everything except the kept session', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{
        'a': source('a'),
        'b': source('b'),
        'c': source('c'),
      });
      await pool.pause(keep: <String>{'b'});
      expect(pool.keys.toSet(), <String>{'b'});
      expect(created[0].disposed, isTrue);
      expect(created[1].disposed, isFalse);
      expect(created[2].disposed, isTrue);
      await pool.disposeAll();
    });

    test('while paused, reconcile only remembers what is wanted', () async {
      final PlayerPool pool = makePool();
      await pool.pause();
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      expect(created, isEmpty);
      await pool.resume();
      expect(created.length, 1);
      await pool.disposeAll();
    });

    test('resume recreates the remembered sessions', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{
        'a': source('a'),
        'b': source('b'),
      });
      await pool.pause();
      expect(pool.keys, isEmpty);
      await pool.resume();
      expect(pool.keys.toSet(), <String>{'a', 'b'});
      expect(created.length, 4);
      await pool.disposeAll();
    });
  });

  group('frame capture', () {
    test('returns the current frame of a playing camera', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      created.single.frame = Uint8List.fromList(<int>[1, 2, 3]);
      created.single.setSize(1280, 720);

      final FrameCaptureService service =
          FrameCaptureService(pool: pool, clock: FakeClock());
      final Result<SnapshotImage> result = await service.capture('a');
      final SnapshotImage image = result.valueOrNull!;
      expect(image.bytes, <int>[1, 2, 3]);
      expect(image.mimeType, 'image/jpeg');
      expect(image.width, 1280);
      expect(image.height, 720);
      expect(image.capturedAt, FakeClock().time);
      await pool.disposeAll();
    });

    test('a camera that is not playing gives an error', () async {
      final PlayerPool pool = makePool();
      final FrameCaptureService service = FrameCaptureService(pool: pool);
      final Result<SnapshotImage> result = await service.capture('missing');
      expect(result.errorOrNull!.errorClass, ErrorClass.unsupportedMedia);
    });

    test('a session without a current frame gives an error', () async {
      final PlayerPool pool = makePool();
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      final FrameCaptureService service = FrameCaptureService(pool: pool);
      final Result<SnapshotImage> result = await service.capture('a');
      expect(result.errorOrNull!.errorClass, ErrorClass.unsupportedMedia);
      await pool.disposeAll();
    });

    test('a session that cannot capture gives an error', () async {
      final PlayerPool pool = PlayerPool(
        sessionFactory: (StreamProtocol p) => NonCapturableSession(),
        startStagger: Duration.zero,
      );
      await pool.reconcile(<String, PlayerSource>{'a': source('a')});
      final FrameCaptureService service = FrameCaptureService(pool: pool);
      final Result<SnapshotImage> result = await service.capture('a');
      expect(result.errorOrNull!.errorClass, ErrorClass.unsupportedMedia);
      await pool.disposeAll();
    });
  });
}
