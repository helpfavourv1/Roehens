import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/services/review_prompt_policy.dart';

import '../../support/fakes.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 10, 31, 12);
  final RatingState ready = RatingState(
    firstLaunchAt: now.subtract(const Duration(days: 10)),
    viewingSessions: Limits.ratingMinViewingSessions,
  );

  group('isDue', () {
    test('is due once the person has used the app enough', () {
      expect(ReviewPromptPolicy.isDue(ready, now, errorThisSession: false), isTrue);
    });

    test('never after an error in this session', () {
      expect(ReviewPromptPolicy.isDue(ready, now, errorThisSession: true), isFalse);
    });

    test('not within a day of an earlier error', () {
      final RatingState state =
          ready.copyWith(lastErrorAt: now.subtract(const Duration(hours: 3)));
      expect(ReviewPromptPolicy.isDue(state, now, errorThisSession: false), isFalse);
    });

    test('allowed again after the quiet period', () {
      final RatingState state =
          ready.copyWith(lastErrorAt: now.subtract(const Duration(hours: 30)));
      expect(ReviewPromptPolicy.isDue(state, now, errorThisSession: false), isTrue);
    });

    test('not before the first days have passed', () {
      final RatingState state =
          ready.copyWith(firstLaunchAt: now.subtract(const Duration(days: 1)));
      expect(ReviewPromptPolicy.isDue(state, now, errorThisSession: false), isFalse);
    });

    test('not without enough viewing sessions', () {
      final RatingState state = ready.copyWith(
        viewingSessions: Limits.ratingMinViewingSessions - 1,
      );
      expect(ReviewPromptPolicy.isDue(state, now, errorThisSession: false), isFalse);
    });

    test('not again within the minimum gap between prompts', () {
      final RatingState state = ready.copyWith(
        promptCount: 1,
        lastPromptAt: now.subtract(const Duration(days: 30)),
      );
      expect(ReviewPromptPolicy.isDue(state, now, errorThisSession: false), isFalse);
    });

    test('again once the gap has passed', () {
      final RatingState state = ready.copyWith(
        promptCount: 1,
        lastPromptAt:
            now.subtract(const Duration(days: Limits.ratingMinDaysBetweenPrompts)),
      );
      expect(ReviewPromptPolicy.isDue(state, now, errorThisSession: false), isTrue);
    });

    test('never beyond the lifetime cap', () {
      final RatingState state = ready.copyWith(
        promptCount: Limits.ratingMaxPrompts,
        lastPromptAt: now.subtract(const Duration(days: 400)),
      );
      expect(ReviewPromptPolicy.isDue(state, now, errorThisSession: false), isFalse);
    });

    test('not without a recorded first launch', () {
      expect(
        ReviewPromptPolicy.isDue(
          const RatingState(viewingSessions: 99),
          now,
          errorThisSession: false,
        ),
        isFalse,
      );
    });
  });

  group('recording', () {
    late FakeKeyValueStore store;
    late FakeClock clock;
    late ReviewPromptPolicy policy;

    setUp(() {
      store = FakeKeyValueStore();
      clock = FakeClock(now.subtract(const Duration(days: 10)));
      policy = ReviewPolicyFactory.create(store, clock);
    });

    test('a new install is not due', () async {
      await policy.recordLaunch();
      expect(await policy.shouldPrompt(), isFalse);
    });

    test('becomes due after days and enough sessions, and prompting resets it',
        () async {
      await policy.recordLaunch();
      clock.advance(const Duration(days: 10));
      for (int i = 0; i < Limits.ratingMinViewingSessions; i++) {
        // A new start of the app for each session.
        policy = ReviewPolicyFactory.create(store, clock);
        await policy.recordLaunch();
        await policy.recordViewingSession();
        await policy.recordViewingSession(); // the same start counts once
      }
      expect(await policy.shouldPrompt(), isTrue);

      await policy.markPrompted();
      expect(await policy.shouldPrompt(), isFalse);
    });

    test('an error in the session blocks the prompt', () async {
      await policy.recordLaunch();
      clock.advance(const Duration(days: 10));
      for (int i = 0; i < Limits.ratingMinViewingSessions; i++) {
        policy = ReviewPolicyFactory.create(store, clock);
        await policy.recordLaunch();
        await policy.recordViewingSession();
      }
      await policy.recordError();
      expect(await policy.shouldPrompt(), isFalse);
    });

    test('state survives a restart', () async {
      await policy.recordLaunch();
      expect(store.values[StorageKeys.ratingState], isNotNull);
      final ReviewPromptPolicy restarted = ReviewPolicyFactory.create(store, clock);
      await restarted.recordLaunch();
      final RatingState saved = RatingState.fromJson(
        <String, Object?>{'firstLaunchAtMillis': clock.time.millisecondsSinceEpoch},
      );
      expect(saved.firstLaunchAt, clock.time);
    });

    test('a corrupt saved state starts clean', () async {
      store.values[StorageKeys.ratingState] = 'not json';
      await policy.recordLaunch();
      expect(await policy.shouldPrompt(), isFalse);
    });
  });
}

/// Builds a policy the way the app does at each start.
class ReviewPolicyFactory {
  ReviewPolicyFactory._();

  static ReviewPromptPolicy create(FakeKeyValueStore store, FakeClock clock) {
    return ReviewPromptPolicy(store: store, clock: clock);
  }
}
