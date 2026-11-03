import 'dart:async';

import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/contracts/discovery_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/models/remote_flags.dart';
import 'package:roehens/core/providers/flags_provider.dart';
import 'package:roehens/core/providers/safe_notifier.dart';

enum DiscoveryStatus {
  idle,
  scanning,
  done,

  /// The `discovery` kill switch is on.
  disabled,

  /// The local network permission was refused (iOS).
  permissionDenied,
}

class DiscoveryState {
  const DiscoveryState({
    this.status = DiscoveryStatus.idle,
    this.results = const <DiscoveryResult>[],
    this.progress = 0,
    this.message,
  });

  final DiscoveryStatus status;
  final List<DiscoveryResult> results;

  /// 0 to 1 while scanning.
  final double progress;

  /// The server's message when the feature is switched off.
  final String? message;

  bool get isScanning => status == DiscoveryStatus.scanning;

  /// A finished run that found nothing; the screen shows tips.
  bool get foundNothing => status == DiscoveryStatus.done && results.isEmpty;

  DiscoveryState copyWith({
    DiscoveryStatus? status,
    List<DiscoveryResult>? results,
    double? progress,
  }) {
    return DiscoveryState(
      status: status ?? this.status,
      results: results ?? this.results,
      progress: progress ?? this.progress,
      message: message,
    );
  }
}

/// One discovery run at a time. A device found by both ONVIF and the sweep is
/// listed once, with the ONVIF details.
class DiscoveryProvider extends SafeValueNotifier<DiscoveryState> {
  DiscoveryProvider({
    required this._discovery,
    required this._flags,
    required this._logger,
    this._permission,
  }) : super(const DiscoveryState());

  static const String _tag = 'discovery';

  final DiscoveryContract _discovery;
  final FlagsProvider _flags;
  final LoggerContract _logger;
  final PermissionContract? _permission;

  StreamSubscription<DiscoveryEvent>? _subscription;

  Future<void> start({Duration timeout = Limits.discoveryTimeout}) async {
    if (value.isScanning) {
      return;
    }
    if (!_flags.isEnabled(RemoteFlagKeys.discovery)) {
      setIfAlive(
        DiscoveryState(
          status: DiscoveryStatus.disabled,
          message: _flags.value.message,
        ),
      );
      return;
    }
    if (!await _hasPermission()) {
      setIfAlive(
        const DiscoveryState(status: DiscoveryStatus.permissionDenied),
      );
      return;
    }
    setIfAlive(const DiscoveryState(status: DiscoveryStatus.scanning));
    _subscription = _discovery
        .discover(timeout: timeout)
        .listen(
          _onEvent,
          onError: (Object error) {
            _logger.warning(_tag, 'discovery failed', error: error);
            _finish();
          },
          onDone: _finish,
        );
  }

  /// Stops the run and keeps what was found.
  Future<void> cancel() async {
    await _subscription?.cancel();
    _subscription = null;
    if (value.isScanning) {
      _finish();
    }
  }

  void clear() {
    setIfAlive(const DiscoveryState());
  }

  Future<bool> _hasPermission() async {
    final PermissionContract? permission = _permission;
    if (permission == null) {
      return true;
    }
    PermissionStatus status = await permission.localNetworkStatus();
    if (status == PermissionStatus.denied) {
      status = await permission.requestLocalNetwork();
    }
    return status != PermissionStatus.denied &&
        status != PermissionStatus.permanentlyDenied;
  }

  void _onEvent(DiscoveryEvent event) {
    switch (event) {
      case DiscoveryFound(:final DiscoveryResult result):
        setIfAlive(value.copyWith(results: _merge(value.results, result)));
      case DiscoveryProgressed(:final double fraction):
        setIfAlive(value.copyWith(progress: fraction.clamp(0, 1)));
      case DiscoveryFinished():
        _finish();
    }
  }

  void _finish() {
    if (value.status != DiscoveryStatus.scanning) {
      return;
    }
    setIfAlive(value.copyWith(status: DiscoveryStatus.done, progress: 1));
  }

  static List<DiscoveryResult> _merge(
    List<DiscoveryResult> current,
    DiscoveryResult found,
  ) {
    final int index = current.indexWhere(
      (DiscoveryResult r) => r.host == found.host,
    );
    if (index == -1) {
      return <DiscoveryResult>[...current, found];
    }
    final bool upgrade =
        current[index].source == DiscoverySource.sweep &&
        found.source == DiscoverySource.onvif;
    if (!upgrade) {
      return current;
    }
    return <DiscoveryResult>[...current]..[index] = found;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
