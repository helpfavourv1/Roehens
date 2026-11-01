import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/pip_contract.dart';

/// Android picture-in-picture through `MainActivity` (channel `roehens/pip`).
/// On iOS it is unsupported and every call does nothing. Not yet verified on a
/// device: the test phone does not support picture-in-picture.
class PipService implements PipContract {
  PipService({MethodChannel? channel, bool? isAndroid, this._logger})
      : _channel = channel ?? const MethodChannel('roehens/pip'),
        _isAndroid = isAndroid ?? Platform.isAndroid {
    if (_isAndroid) {
      _channel.setMethodCallHandler(_onCall);
    }
  }

  static const String _tag = 'pip';

  final MethodChannel _channel;
  final bool _isAndroid;
  final LoggerContract? _logger;
  final ValueNotifier<bool> _inPip = ValueNotifier<bool>(false);
  bool _supported = false;

  @override
  bool get isSupported => _isAndroid && _supported;

  @override
  ValueListenable<bool> get isInPip => _inPip;

  /// Asks the phone whether it supports picture-in-picture. Call once at start.
  Future<void> initialize() async {
    if (!_isAndroid) {
      return;
    }
    try {
      _supported = await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException catch (error) {
      _logger?.warning(_tag, 'support check failed', error: error);
    } on MissingPluginException {
      _supported = false;
    }
  }

  @override
  Future<bool> enter() async {
    if (!isSupported) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('enter') ?? false;
    } on PlatformException catch (error) {
      _logger?.warning(_tag, 'enter failed', error: error);
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<Object?> _onCall(MethodCall call) async {
    if (call.method == 'pipChanged') {
      _inPip.value = call.arguments == true;
    }
    return null;
  }

  void dispose() {
    if (_isAndroid) {
      _channel.setMethodCallHandler(null);
    }
    _inPip.dispose();
  }
}
