import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/platform/system/pip_service.dart';

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('roehens/pip');
  final List<String> calls = <String>[];
  bool supported = true;
  bool entered = true;

  setUp(() {
    calls.clear();
    supported = true;
    entered = true;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall call,
    ) async {
      calls.add(call.method);
      if (call.method == 'isSupported') {
        return supported;
      }
      if (call.method == 'enter') {
        return entered;
      }
      return null;
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('on iOS it is unsupported and never calls the platform', () async {
    final PipService pip = PipService(channel: channel, isAndroid: false);
    await pip.initialize();

    expect(pip.isSupported, isFalse);
    expect(await pip.enter(), isFalse);
    expect(calls, isEmpty);
    pip.dispose();
  });

  test('on a supporting Android phone it enters picture-in-picture', () async {
    final PipService pip = PipService(channel: channel, isAndroid: true);
    expect(pip.isSupported, isFalse);
    await pip.initialize();

    expect(pip.isSupported, isTrue);
    expect(await pip.enter(), isTrue);
    expect(calls, <String>['isSupported', 'enter']);
    pip.dispose();
  });

  test(
    'a phone that does not support it is refused before asking to enter',
    () async {
      supported = false;
      final PipService pip = PipService(channel: channel, isAndroid: true);
      await pip.initialize();

      expect(pip.isSupported, isFalse);
      expect(await pip.enter(), isFalse);
      expect(calls, <String>['isSupported']);
      pip.dispose();
    },
  );

  test('the system refusing is reported as false', () async {
    entered = false;
    final PipService pip = PipService(channel: channel, isAndroid: true);
    await pip.initialize();
    expect(await pip.enter(), isFalse);
    pip.dispose();
  });

  test('follows the window entering and leaving picture-in-picture', () async {
    final PipService pip = PipService(channel: channel, isAndroid: true);
    expect(pip.isInPip.value, isFalse);

    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'roehens/pip',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('pipChanged', true),
      ),
      (_) {},
    );
    expect(pip.isInPip.value, isTrue);

    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'roehens/pip',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('pipChanged', false),
      ),
      (_) {},
    );
    expect(pip.isInPip.value, isFalse);
    pip.dispose();
  });
}
