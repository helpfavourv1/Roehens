import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/diagnostics_report.dart';

/// The network checks behind the Diagnostics screen. Each runs on its own and
/// never by itself: the screen calls one when its button is pressed.
abstract interface class NetworkDiagnosticsContract {
  /// This phone's address on the local network and its gateway.
  Future<CheckOutcome> localNetwork();

  /// Whether a camera answers on the local network, by the connection tester.
  Future<CheckOutcome> lanReachability(
    Camera camera,
    CameraCredentials credentials,
  );

  /// Whether [host] resolves to an address.
  Future<CheckOutcome> hostResolution(String host);

  /// Whether [host]:[port] accepts a connection from this phone. Run it on
  /// mobile data to test the way in from outside.
  Future<CheckOutcome> hostPort(String host, int port);

  /// The public address the internet sees for this phone's connection, from
  /// the one lookup service named in the privacy policy. Sends no camera or
  /// personal data.
  Future<CheckOutcome> publicAddress();
}
