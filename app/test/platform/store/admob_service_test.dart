import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/platform/store/admob_service.dart';
import 'package:roehens/platform/store/store_config.dart';

class FakeAdsBackend implements AdsBackend {
  int initializations = 0;
  bool failInitialize = false;
  bool failLoad = false;
  double nextHeight = 60;
  bool returnNull = false;
  final List<String> unitIds = <String>[];
  final List<int> widths = <int>[];
  final List<_Banner> banners = <_Banner>[];
  Completer<void>? hold;

  @override
  Future<void> initialize() async {
    initializations++;
    if (failInitialize) {
      throw StateError('no ads');
    }
  }

  @override
  Future<LoadedBanner?> loadBanner({required String unitId, required int widthDp}) async {
    unitIds.add(unitId);
    widths.add(widthDp);
    final Completer<void>? gate = hold;
    if (gate != null) {
      await gate.future;
    }
    if (failLoad) {
      throw StateError('load failed');
    }
    if (returnNull) {
      return null;
    }
    final _Banner banner = _Banner(nextHeight);
    banners.add(banner);
    return LoadedBanner(height: banner.height, view: banner, dispose: banner.dispose);
  }
}

class _Banner {
  _Banner(this.height);

  final double height;
  bool disposed = false;

  void dispose() => disposed = true;
}

void main() {
  late FakeAdsBackend backend;
  late AdMobService service;

  setUp(() {
    backend = FakeAdsBackend();
    service = AdMobService(config: StoreConfig.googlePlay, backend: backend);
  });

  test('nothing is shown before the SDK is started', () async {
    await service.loadBanner(widthDp: 360);
    expect(service.bannerHeight.value, 0);
    expect(service.bannerView, isNull);
    expect(backend.widths, isEmpty);
  });

  test('starting twice starts the SDK once', () async {
    await service.initialize();
    await service.initialize();
    expect(backend.initializations, 1);
  });

  test('a failed start never throws and keeps ads off', () async {
    backend.failInitialize = true;
    await service.initialize();
    await service.loadBanner(widthDp: 360);
    expect(service.bannerHeight.value, 0);
    expect(backend.widths, isEmpty);
  });

  test('a loaded banner reserves its height and exposes its view', () async {
    await service.initialize();
    await service.loadBanner(widthDp: 360);
    expect(service.bannerHeight.value, 60);
    expect(service.bannerView, same(backend.banners.single));
    expect(backend.unitIds.single, StoreConfig.testBannerAndroid);
    expect(backend.widths.single, 360);
  });

  test('the reserved height never exceeds the cap', () async {
    backend.nextHeight = 250;
    await service.initialize();
    await service.loadBanner(widthDp: 360);
    expect(service.bannerHeight.value, 100);
  });

  test('a failed load collapses the slot and releases the old banner', () async {
    await service.initialize();
    await service.loadBanner(widthDp: 360);
    final _Banner first = backend.banners.single;

    backend.returnNull = true;
    await service.loadBanner(widthDp: 360);
    expect(service.bannerHeight.value, 0);
    expect(service.bannerView, isNull);
    expect(first.disposed, isTrue);
  });

  test('a backend that throws collapses the slot without throwing', () async {
    await service.initialize();
    backend.failLoad = true;
    await service.loadBanner(widthDp: 360);
    expect(service.bannerHeight.value, 0);
  });

  test('a new banner replaces and releases the previous one', () async {
    await service.initialize();
    await service.loadBanner(widthDp: 360);
    await service.loadBanner(widthDp: 400);
    expect(backend.banners.length, 2);
    expect(backend.banners.first.disposed, isTrue);
    expect(backend.banners.last.disposed, isFalse);
    expect(service.bannerView, same(backend.banners.last));
  });

  test('a load that finishes after a newer request is discarded', () async {
    await service.initialize();
    backend.hold = Completer<void>();
    final Future<void> slow = service.loadBanner(widthDp: 360);
    await Future<void>.delayed(Duration.zero);

    final Completer<void> gate = backend.hold!;
    backend.hold = null;
    await service.loadBanner(widthDp: 400); // newer request finishes first
    final _Banner newer = backend.banners.single;

    gate.complete();
    await slow;
    expect(backend.banners.length, 2);
    expect(backend.banners.first.disposed, isFalse); // the newer one is not first in the list
    expect(service.bannerView, same(newer));
    expect(newer.disposed, isFalse);
    // The stale banner was released.
    expect(backend.banners.where((_Banner b) => b.disposed).length, 1);
  });

  test('disposing collapses the slot and ignores a load still in flight', () async {
    await service.initialize();
    await service.loadBanner(widthDp: 360);
    final _Banner shown = backend.banners.single;

    backend.hold = Completer<void>();
    final Future<void> inFlight = service.loadBanner(widthDp: 360);
    await Future<void>.delayed(Duration.zero);
    service.disposeBanner();
    expect(service.bannerHeight.value, 0);
    expect(shown.disposed, isTrue);

    backend.hold!.complete();
    await inFlight;
    expect(service.bannerHeight.value, 0);
    expect(service.bannerView, isNull);
    expect(backend.banners.last.disposed, isTrue);
  });

  test('a width of zero is ignored', () async {
    await service.initialize();
    await service.loadBanner(widthDp: 0);
    expect(backend.widths, isEmpty);
  });

  test('listeners hear height changes', () async {
    await service.initialize();
    final List<double> heights = <double>[];
    service.bannerHeight.addListener(() => heights.add(service.bannerHeight.value));
    await service.loadBanner(widthDp: 360);
    service.disposeBanner();
    expect(heights, <double>[60, 0]);
  });
}
