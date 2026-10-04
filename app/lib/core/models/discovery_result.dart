import 'package:flutter/foundation.dart';

/// How a device was found.
enum DiscoverySource { onvif, sweep }

List<String> _strings(Object? value) {
  return (value as List<Object?>? ?? const <Object?>[])
      .map((Object? item) => item! as String)
      .toList();
}

/// A device found on the network. Unauthenticated until the person supplies
/// credentials.
class DiscoveryResult {
  const DiscoveryResult({
    required this.host,
    required this.port,
    required this.source,
    this.name,
    this.model,
    this.scopes = const <String>[],
    this.xaddrs = const <String>[],
  });

  factory DiscoveryResult.fromJson(Map<String, Object?> json) {
    return DiscoveryResult(
      host: json['host']! as String,
      port: json['port']! as int,
      source: DiscoverySource.values.byName(json['source']! as String),
      name: json['name'] as String?,
      model: json['model'] as String?,
      scopes: _strings(json['scopes']),
      xaddrs: _strings(json['xaddrs']),
    );
  }

  final String host;
  final int port;
  final DiscoverySource source;
  final String? name;
  final String? model;

  /// ONVIF scope URIs.
  final List<String> scopes;

  /// ONVIF device service addresses.
  final List<String> xaddrs;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'host': host,
      'port': port,
      'source': source.name,
      'name': name,
      'model': model,
      'scopes': scopes,
      'xaddrs': xaddrs,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is DiscoveryResult &&
        other.host == host &&
        other.port == port &&
        other.source == source &&
        other.name == name &&
        other.model == model &&
        listEquals(other.scopes, scopes) &&
        listEquals(other.xaddrs, xaddrs);
  }

  @override
  int get hashCode => Object.hash(
        host,
        port,
        source,
        name,
        model,
        Object.hashAll(scopes),
        Object.hashAll(xaddrs),
      );
}
