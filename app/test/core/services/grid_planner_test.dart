import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/stream_profile.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/grid_planner.dart';

import '../../support/fakes.dart';

Camera cam(
  String id, {
  StreamProtocol protocol = StreamProtocol.rtsp,
  String? sub = '/sub',
}) {
  return testCamera(id: id).copyWith(protocol: protocol, subPath: sub);
}

void main() {
  const GridPlanner planner = GridPlanner();

  test('tiles beyond the decoder budget become posters, in screen order', () {
    final List<Camera> cameras = <Camera>[
      for (int i = 1; i <= 6; i++) cam('c$i'),
    ];
    final GridPlan plan = planner.plan(visible: cameras, decoderBudget: 4);
    expect(plan.liveCount, 4);
    expect(
      plan.tiles.map((TilePlan t) => t.mode),
      <TileMode>[
        TileMode.live,
        TileMode.live,
        TileMode.live,
        TileMode.live,
        TileMode.poster,
        TileMode.poster,
      ],
    );
  });

  test('the plan keeps the input order', () {
    final List<Camera> cameras = <Camera>[cam('b'), cam('a'), cam('c')];
    final GridPlan plan = planner.plan(visible: cameras, decoderBudget: 8);
    expect(plan.tiles.map((TilePlan t) => t.cameraId), <String>['b', 'a', 'c']);
  });

  test('the focused tile always plays and uses the main stream', () {
    final List<Camera> cameras = <Camera>[
      for (int i = 1; i <= 6; i++) cam('c$i'),
    ];
    final GridPlan plan = planner.plan(
      visible: cameras,
      decoderBudget: 2,
      focusedId: 'c6',
    );
    final TilePlan focused = plan.planFor('c6')!;
    expect(focused.mode, TileMode.live);
    expect(focused.streamKind, StreamKind.main);
    expect(plan.liveCount, 2);
    expect(plan.planFor('c1')!.mode, TileMode.live);
    expect(plan.planFor('c2')!.mode, TileMode.poster);
  });

  test('a focused tile plays even with a budget of zero', () {
    final GridPlan plan = planner.plan(
      visible: <Camera>[cam('a'), cam('b')],
      decoderBudget: 0,
      focusedId: 'b',
    );
    expect(plan.planFor('b')!.mode, TileMode.live);
    expect(plan.planFor('a')!.mode, TileMode.poster);
  });

  test('grid tiles use the substream when the camera has one', () {
    final GridPlan plan = planner.plan(
      visible: <Camera>[cam('a'), cam('b', sub: null)],
      decoderBudget: 4,
    );
    expect(plan.planFor('a')!.streamKind, StreamKind.sub);
    expect(plan.planFor('b')!.streamKind, StreamKind.main);
  });

  test('substreams can be switched off', () {
    final GridPlan plan = planner.plan(
      visible: <Camera>[cam('a')],
      decoderBudget: 4,
      preferSubstream: false,
    );
    expect(plan.planFor('a')!.streamKind, StreamKind.main);
  });

  test('snapshot cameras cost nothing and are always live', () {
    final List<Camera> cameras = <Camera>[
      cam('r1'),
      cam('r2'),
      cam('s1', protocol: StreamProtocol.httpSnapshot),
      cam('s2', protocol: StreamProtocol.httpSnapshot),
    ];
    final GridPlan plan = planner.plan(visible: cameras, decoderBudget: 1);
    expect(plan.planFor('r1')!.mode, TileMode.live);
    expect(plan.planFor('r2')!.mode, TileMode.poster);
    expect(plan.planFor('s1')!.mode, TileMode.live);
    expect(plan.planFor('s2')!.mode, TileMode.live);
  });

  test('only HTTP cameras refresh their poster', () {
    final List<Camera> cameras = <Camera>[
      cam('r1'),
      cam('r2'),
      cam('m1', protocol: StreamProtocol.mjpeg),
      cam('m2', protocol: StreamProtocol.mjpeg),
    ];
    final GridPlan plan = planner.plan(visible: cameras, decoderBudget: 1);
    expect(plan.planFor('r2')!.mode, TileMode.poster);
    expect(plan.planFor('r2')!.refreshPoster, isFalse);
    expect(plan.planFor('m2')!.mode, TileMode.poster);
    expect(plan.planFor('m2')!.refreshPoster, isTrue);
    expect(plan.planFor('r1')!.refreshPoster, isFalse);
  });

  test('memory pressure with a focused tile leaves only that tile live', () {
    final GridPlan plan = planner.plan(
      visible: <Camera>[cam('a'), cam('b'), cam('c')],
      decoderBudget: 4,
      focusedId: 'b',
      lowMemory: true,
    );
    expect(plan.liveCount, 1);
    expect(plan.planFor('b')!.mode, TileMode.live);
  });

  test('memory pressure in the grid halves the budget but keeps one tile', () {
    final List<Camera> cameras = <Camera>[
      for (int i = 1; i <= 6; i++) cam('c$i'),
    ];
    expect(
      planner.plan(visible: cameras, decoderBudget: 4, lowMemory: true).liveCount,
      2,
    );
    expect(
      planner.plan(visible: cameras, decoderBudget: 1, lowMemory: true).liveCount,
      1,
    );
  });

  test('a focused id that is not on screen is ignored', () {
    final GridPlan plan = planner.plan(
      visible: <Camera>[cam('a'), cam('b')],
      decoderBudget: 4,
      focusedId: 'gone',
    );
    expect(plan.liveCount, 2);
    expect(plan.planFor('a')!.streamKind, StreamKind.sub);
  });

  test('nothing on screen gives an empty plan', () {
    final GridPlan plan = planner.plan(visible: <Camera>[], decoderBudget: 4);
    expect(plan.tiles, isEmpty);
    expect(plan.liveCount, 0);
  });

  test('budgets match the specification', () {
    expect(GridPlanner.budgetFor(isTablet: false), 4);
    expect(GridPlanner.budgetFor(isTablet: true), 8);
  });
}
