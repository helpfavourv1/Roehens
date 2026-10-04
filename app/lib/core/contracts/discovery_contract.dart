import 'package:roehens/core/models/discovery_result.dart';

/// Events of one discovery run.
sealed class DiscoveryEvent {
  const DiscoveryEvent();
}

/// A device was found.
final class DiscoveryFound extends DiscoveryEvent {
  const DiscoveryFound(this.result);

  final DiscoveryResult result;
}

/// Scan progress, from 0 to 1.
final class DiscoveryProgressed extends DiscoveryEvent {
  const DiscoveryProgressed(this.fraction);

  final double fraction;
}

/// The run ended; no more events follow.
final class DiscoveryFinished extends DiscoveryEvent {
  const DiscoveryFinished();
}

/// Finds cameras on the local network by ONVIF probe and subnet sweep.
abstract interface class DiscoveryContract {
  /// Starts a run. Cancelling the subscription stops it.
  Stream<DiscoveryEvent> discover({required Duration timeout});
}
