import 'dart:io';

import 'package:flutter/services.dart';

/// Android-only network helpers (see `MulticastLockChannel.kt`): the Wi-Fi
/// multicast lock, the Wi-Fi gateway, and this app's system settings page. On
/// other platforms every method returns its "nothing" value without a call.
class MulticastLockChannel {
  MulticastLockChannel({MethodChannel? channel, bool? isAndroid})
      : _channel = channel ?? const MethodChannel('roehens/network'),
        _isAndroid = isAndroid ?? Platform.isAndroid;

  final MethodChannel _channel;
  final bool _isAndroid;

  /// Holds the lock; true when it is held.
  Future<bool> acquire() async {
    if (!_isAndroid) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('acquireMulticastLock') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> release() async {
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('releaseMulticastLock');
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  /// The Wi-Fi gateway address, or null when unknown.
  Future<String?> gateway() async {
    if (!_isAndroid) {
      return null;
    }
    try {
      return await _channel.invokeMethod<String>('gateway');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Opens this app's page in the Android settings.
  Future<bool> openAppSettings() async {
    if (!_isAndroid) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('openAppSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
