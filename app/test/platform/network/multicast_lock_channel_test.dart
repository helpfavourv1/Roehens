import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/platform/network/multicast_lock_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('test/network');
  final List<String> calls = <String>[];

  void mock(Future<Object?>? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  setUp(calls.clear);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('on Android the calls go to the native side', () async {
    mock((MethodCall call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'acquireMulticastLock':
          return true;
        case 'gateway':
          return '192.168.1.254';
        case 'openAppSettings':
          return true;
        default:
          return null;
      }
    });
    final MulticastLockChannel network =
        MulticastLockChannel(channel: channel, isAndroid: true);
    expect(await network.acquire(), isTrue);
    expect(await network.gateway(), '192.168.1.254');
    expect(await network.openAppSettings(), isTrue);
    await network.release();
    expect(calls, <String>[
      'acquireMulticastLock',
      'gateway',
      'openAppSettings',
      'releaseMulticastLock',
    ]);
  });

  test('off Android nothing is called and the answers are empty', () async {
    mock((MethodCall call) async {
      calls.add(call.method);
      return true;
    });
    final MulticastLockChannel network =
        MulticastLockChannel(channel: channel, isAndroid: false);
    expect(await network.acquire(), isFalse);
    expect(await network.gateway(), isNull);
    expect(await network.openAppSettings(), isFalse);
    await network.release();
    expect(calls, isEmpty);
  });

  test('a native failure is swallowed', () async {
    mock((MethodCall call) async {
      throw PlatformException(code: 'boom');
    });
    final MulticastLockChannel network =
        MulticastLockChannel(channel: channel, isAndroid: true);
    expect(await network.acquire(), isFalse);
    expect(await network.gateway(), isNull);
    expect(await network.openAppSettings(), isFalse);
    await network.release();
  });

  test('a missing native side is swallowed', () async {
    mock((MethodCall call) async => throw MissingPluginException());
    final MulticastLockChannel network =
        MulticastLockChannel(channel: channel, isAndroid: true);
    expect(await network.acquire(), isFalse);
    expect(await network.gateway(), isNull);
  });
}
