import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/platform/system/haptics_service.dart';
import 'package:roehens/platform/system/orientation_service.dart';
import 'package:roehens/platform/system/screen_wake_service.dart';

import '../../support/fakes.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  final List<MethodCall> calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('HapticsService', () {
    test('sends feedback when enabled', () async {
      final HapticsService haptics = HapticsService(isEnabled: () => true);
      await haptics.light();
      await haptics.selection();
      await haptics.success();
      await haptics.warning();

      expect(
        calls.where((MethodCall c) => c.method == 'HapticFeedback.vibrate'),
        hasLength(4),
      );
    });

    test('sends nothing when the person turned haptics off', () async {
      final HapticsService haptics = HapticsService(isEnabled: () => false);
      await haptics.light();
      await haptics.warning();

      expect(calls, isEmpty);
    });

    test('reads the setting on every call', () async {
      bool enabled = false;
      final HapticsService haptics = HapticsService(isEnabled: () => enabled);
      await haptics.light();
      expect(calls, isEmpty);
      enabled = true;
      await haptics.light();
      expect(calls, hasLength(1));
    });
  });

  group('OrientationService', () {
    test('locks landscape and restores all orientations', () async {
      final OrientationService service = OrientationService(logger: FakeLogger());
      await service.lockLandscape();
      await service.allowAll();

      final List<MethodCall> orientation = calls
          .where((MethodCall c) => c.method == 'SystemChrome.setPreferredOrientations')
          .toList();
      expect(orientation, hasLength(2));
      expect(orientation.first.arguments, hasLength(2));
      expect(orientation.last.arguments, hasLength(4));
    });

    test('immersive mode hides and restores the system bars', () async {
      final OrientationService service = OrientationService(logger: FakeLogger());
      await service.setImmersive(immersive: true);
      await service.setImmersive(immersive: false);

      final List<MethodCall> modes = calls
          .where((MethodCall c) => c.method == 'SystemChrome.setEnabledSystemUIMode')
          .toList();
      expect(modes.first.arguments, 'SystemUiMode.immersiveSticky');
      expect(modes.last.arguments, 'SystemUiMode.edgeToEdge');
    });
  });

  group('ScreenWakeService', () {
    test('skips calls that would change nothing', () async {
      final List<bool> requests = <bool>[];
      final ScreenWakeService service = ScreenWakeService(
        logger: FakeLogger(),
        backend: ({required bool enable}) async => requests.add(enable),
      );
      await service.setAwake(true);
      await service.setAwake(true);
      await service.setAwake(false);
      await service.setAwake(false);

      expect(requests, <bool>[true, false]);
      expect(service.isAwake, isFalse);
    });

    test('a failing plugin is logged and the state stays unchanged', () async {
      final FakeLogger logger = FakeLogger();
      final ScreenWakeService service = ScreenWakeService(
        logger: logger,
        backend: ({required bool enable}) async => throw Exception('no activity'),
      );
      await service.setAwake(true);

      expect(service.isAwake, isFalse);
      expect(logger.entries, isNotEmpty);
    });
  });
}
