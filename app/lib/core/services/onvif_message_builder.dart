import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/ptz_command.dart';
import 'package:roehens/core/services/ptz_math.dart';

/// Credentials plus the difference between the camera's clock and ours. ONVIF
/// rejects a signed request whose timestamp is too far from the camera's time,
/// so the offset is learned once with GetSystemDateAndTime.
class OnvifAuth {
  const OnvifAuth(this.credentials, {this.timeOffset = Duration.zero});

  final CameraCredentials credentials;
  final Duration timeOffset;
}

/// Builds the SOAP requests of the ONVIF device, media and PTZ services, signed
/// with a WS-Security UsernameToken (password digest) when [OnvifAuth] is given.
class OnvifMessageBuilder {
  OnvifMessageBuilder({this.clock = const SystemClock(), Random? random})
      : _random = random ?? Random.secure();

  final ClockContract clock;
  final Random _random;

  static const String _passwordDigestType =
      'http://docs.oasis-open.org/wss/2004/01/'
      'oasis-200401-wss-username-token-profile-1.0#PasswordDigest';
  static const String _base64BinaryType =
      'http://docs.oasis-open.org/wss/2004/01/'
      'oasis-200401-wss-soap-message-security-1.0#Base64Binary';

  /// Base64(SHA-1(nonce + created + password)), as WS-Security defines it.
  static String passwordDigest({
    required Uint8List nonce,
    required String created,
    required String password,
  }) {
    final List<int> input = <int>[
      ...nonce,
      ...utf8.encode(created),
      ...utf8.encode(password),
    ];
    return base64.encode(sha1.convert(input).bytes);
  }

  static String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static String _timestamp(DateTime time) {
    final DateTime utc = time.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
        '${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}Z';
  }

  static String _number(double value) => value.toStringAsFixed(3);

  String _securityHeader(OnvifAuth auth, Uint8List? nonce, DateTime? created) {
    final Uint8List nonceBytes = nonce ??
        Uint8List.fromList(
          List<int>.generate(16, (int _) => _random.nextInt(256)),
        );
    final String createdText =
        _timestamp(created ?? clock.now().add(auth.timeOffset));
    final String digest = passwordDigest(
      nonce: nonceBytes,
      created: createdText,
      password: auth.credentials.password,
    );
    return '<s:Header>'
        '<wsse:Security s:mustUnderstand="1" '
        'xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/'
        'oasis-200401-wss-wssecurity-secext-1.0.xsd" '
        'xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/'
        'oasis-200401-wss-wssecurity-utility-1.0.xsd">'
        '<wsse:UsernameToken>'
        '<wsse:Username>${_escape(auth.credentials.username)}</wsse:Username>'
        '<wsse:Password Type="$_passwordDigestType">$digest</wsse:Password>'
        '<wsse:Nonce EncodingType="$_base64BinaryType">'
        '${base64.encode(nonceBytes)}</wsse:Nonce>'
        '<wsu:Created>$createdText</wsu:Created>'
        '</wsse:UsernameToken></wsse:Security></s:Header>';
  }

  /// Wraps [body] in a SOAP envelope. [nonce] and [created] exist so tests can
  /// produce a fixed signature.
  String envelope(
    String body, {
    OnvifAuth? auth,
    Uint8List? nonce,
    DateTime? created,
  }) {
    final bool signed = auth != null && !auth.credentials.isEmpty;
    return '<?xml version="1.0" encoding="UTF-8"?>'
        '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" '
        'xmlns:tds="http://www.onvif.org/ver10/device/wsdl" '
        'xmlns:trt="http://www.onvif.org/ver10/media/wsdl" '
        'xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" '
        'xmlns:tt="http://www.onvif.org/ver10/schema">'
        '${signed ? _securityHeader(auth, nonce, created) : ''}'
        '<s:Body>$body</s:Body></s:Envelope>';
  }

  /// Needs no signature; used to learn the camera's clock.
  String getSystemDateAndTime() => envelope('<tds:GetSystemDateAndTime/>');

  String getDeviceInformation({OnvifAuth? auth}) {
    return envelope('<tds:GetDeviceInformation/>', auth: auth);
  }

  /// Asks the device where its media and PTZ services live.
  String getCapabilities({OnvifAuth? auth}) {
    return envelope(
      '<tds:GetCapabilities><tds:Category>All</tds:Category></tds:GetCapabilities>',
      auth: auth,
    );
  }

  String getProfiles({OnvifAuth? auth}) {
    return envelope('<trt:GetProfiles/>', auth: auth);
  }

  /// RTSP address of one profile, requested for unicast RTP over RTSP.
  String getStreamUri(String profileToken, {OnvifAuth? auth}) {
    return envelope(
      '<trt:GetStreamUri><trt:StreamSetup>'
      '<tt:Stream>RTP-Unicast</tt:Stream>'
      '<tt:Transport><tt:Protocol>RTSP</tt:Protocol></tt:Transport>'
      '</trt:StreamSetup>'
      '<trt:ProfileToken>${_escape(profileToken)}</trt:ProfileToken>'
      '</trt:GetStreamUri>',
      auth: auth,
    );
  }

  String continuousMove(
    String profileToken, {
    required PtzVelocity velocity,
    OnvifAuth? auth,
  }) {
    return envelope(
      '<tptz:ContinuousMove>'
      '<tptz:ProfileToken>${_escape(profileToken)}</tptz:ProfileToken>'
      '<tptz:Velocity>'
      '<tt:PanTilt x="${_number(velocity.pan)}" y="${_number(velocity.tilt)}"/>'
      '<tt:Zoom x="${_number(velocity.zoom)}"/>'
      '</tptz:Velocity></tptz:ContinuousMove>',
      auth: auth,
    );
  }

  String stopMove(String profileToken, {OnvifAuth? auth}) {
    return envelope(
      '<tptz:Stop>'
      '<tptz:ProfileToken>${_escape(profileToken)}</tptz:ProfileToken>'
      '<tptz:PanTilt>true</tptz:PanTilt><tptz:Zoom>true</tptz:Zoom>'
      '</tptz:Stop>',
      auth: auth,
    );
  }

  String gotoHome(String profileToken, {OnvifAuth? auth}) {
    return envelope(
      '<tptz:GotoHomePosition>'
      '<tptz:ProfileToken>${_escape(profileToken)}</tptz:ProfileToken>'
      '</tptz:GotoHomePosition>',
      auth: auth,
    );
  }

  String gotoPreset(
    String profileToken,
    String presetToken, {
    OnvifAuth? auth,
  }) {
    return envelope(
      '<tptz:GotoPreset>'
      '<tptz:ProfileToken>${_escape(profileToken)}</tptz:ProfileToken>'
      '<tptz:PresetToken>${_escape(presetToken)}</tptz:PresetToken>'
      '</tptz:GotoPreset>',
      auth: auth,
    );
  }

  /// The request that carries out [command] on [profileToken].
  String ptzRequest(
    PtzCommand command,
    String profileToken, {
    OnvifAuth? auth,
  }) {
    switch (command.kind) {
      case PtzCommandKind.continuous:
        return continuousMove(
          profileToken,
          velocity: PtzMath.velocityFor(command),
          auth: auth,
        );
      case PtzCommandKind.stop:
        return stopMove(profileToken, auth: auth);
      case PtzCommandKind.home:
        return gotoHome(profileToken, auth: auth);
      case PtzCommandKind.preset:
        return gotoPreset(profileToken, command.presetToken ?? '', auth: auth);
    }
  }
}
