import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/grid_layout.dart';
import 'package:roehens/core/providers/layout_provider.dart';

import '../../support/fakes.dart';

void main() {
  late FakeStorage storage;
  late FakeKeyValueStore store;
  late LayoutProvider provider;

  List<Camera> cameras(int count) {
    return <Camera>[
      for (int i = 0; i < count; i++)
        testCamera(id: 'c$i', name: 'Cam $i', sortIndex: i),
    ];
  }

  setUp(() {
    storage = FakeStorage();
    store = FakeKeyValueStore();
    provider = LayoutProvider(
      storage: storage,
      store: store,
      logger: FakeLogger(),
    );
  });

  tearDown(() => provider.dispose());

  test('starts with a four-tile layout', () async {
    await provider.load();
    expect(provider.value.pageSize, 4);
    expect(provider.value.id, LayoutProvider.defaultLayoutId);
  });

  test('loads the saved active layout', () async {
    storage.layouts['a'] = GridLayout.forPageSize(id: 'a', pageSize: 6);
    storage.layouts['b'] = GridLayout.forPageSize(id: 'b', pageSize: 9);
    store.values[StorageKeys.activeLayoutId] = 'b';
    await provider.load();

    expect(provider.value.id, 'b');
    expect(provider.value.pageSize, 9);
  });

  test('changing the grid size saves it and keeps the page in range', () async {
    provider.setPage(2, cameraCount: 12);
    expect(provider.page.value, 2);

    await provider.setPageSize(9, cameraCount: 12);
    expect(provider.value.pageSize, 9);
    expect(provider.page.value, 1);
    expect(storage.layouts[LayoutProvider.defaultLayoutId]?.pageSize, 9);
    expect(
      store.values[StorageKeys.activeLayoutId],
      LayoutProvider.defaultLayoutId,
    );
  });

  test('an unsupported grid size is ignored', () async {
    await provider.setPageSize(7, cameraCount: 3);
    expect(provider.value.pageSize, 4);
    expect(storage.layouts, isEmpty);
  });

  test('auto-cycle interval accepts only supported values or null', () async {
    await provider.setAutoCycleSeconds(30);
    expect(provider.value.autoCycleSeconds, 30);
    await provider.setAutoCycleSeconds(7);
    expect(provider.value.autoCycleSeconds, 30);
    await provider.setAutoCycleSeconds(null);
    expect(provider.value.autoCycleSeconds, isNull);
  });

  test(
    'new cameras go last and removed cameras drop out of the order',
    () async {
      await provider.setCameraOrder(<String>['c2', 'gone', 'c0']);
      final List<Camera> list = cameras(4);

      expect(provider.orderedIds(list), <String>['c2', 'c0', 'c1', 'c3']);

      await provider.syncCameras(list);
      expect(provider.value.cameraIds, <String>['c2', 'c0', 'c1', 'c3']);
    },
  );

  test('syncing an unchanged order saves nothing', () async {
    final List<Camera> list = cameras(2);
    await provider.syncCameras(list);
    storage.layouts.clear();
    await provider.syncCameras(list);
    expect(storage.layouts, isEmpty);
  });

  test('cameras on a page follow the layout order', () async {
    await provider.setCameraOrder(<String>['c5', 'c4', 'c3', 'c2', 'c1', 'c0']);
    final List<Camera> list = cameras(6);

    expect(
      provider.camerasOnPage(list, pageIndex: 0).map((Camera c) => c.id),
      <String>['c5', 'c4', 'c3', 'c2'],
    );
    expect(
      provider.camerasOnPage(list, pageIndex: 1).map((Camera c) => c.id),
      <String>['c1', 'c0'],
    );
    expect(provider.camerasOnPage(list, pageIndex: 2), isEmpty);
  });

  test('next and previous page wrap around', () {
    provider.nextPage(cameraCount: 9);
    expect(provider.page.value, 1);
    provider.nextPage(cameraCount: 9);
    provider.nextPage(cameraCount: 9);
    expect(provider.page.value, 0);
    provider.previousPage(cameraCount: 9);
    expect(provider.page.value, 2);
  });

  test('one page means paging stays on page zero', () {
    provider.nextPage(cameraCount: 2);
    expect(provider.page.value, 0);
    provider.setPage(5, cameraCount: 2);
    expect(provider.page.value, 0);
  });
}
