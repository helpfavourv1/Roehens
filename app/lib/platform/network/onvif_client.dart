import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:roehens/core/contracts/clock_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/error_mapper.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/ptz_command.dart';
import 'package:roehens/core/services/onvif_message_builder.dart';
import 'package:roehens/core/services/onvif_response_parser.dart';
import 'package:roehens/platform/network/http_credentials.dart';

/// Everything learned about a camera by [OnvifClient.connect].
class OnvifDevice {
  const OnvifDevice({
    required this.deviceService,
    required this.info,
    required this.profiles,
    required this.mediaService,
    required this.ptzService,
    required this.clockOffset,
  });

  final Uri deviceService;
  final OnvifDeviceInfo info;
  final List<OnvifProfile> profiles;
  final Uri mediaService;

  /// Null when the camera has no PTZ service.
  final Uri? ptzService;

  /// How far the camera's clock is ahead of ours.
  final Duration clockOffset;

  OnvifAuth authFor(CameraCredentials credentials) {
    return OnvifAuth(credentials, timeOffset: clockOffset);
  }
}

/// ONVIF over HTTP (SOAP). Requests are signed with a WS-Security password
/// digest; if the camera also wants HTTP Basic or Digest authentication, that
/// is answered too. Every failure is returned as an [AppError].
class OnvifClient {
  OnvifClient({
    OnvifMessageBuilder? builder,
    this.parser = const OnvifResponseParser(),
    this.errorMapper = const ErrorMapper(),
    this.timeout = const Duration(seconds: 8),
    this.clock = const SystemClock(),
    HttpClient Function()? clientFactory,
  })  : builder = builder ?? OnvifMessageBuilder(clock: clock),
        _clientFactory = clientFactory ?? HttpClient.new;

  final OnvifMessageBuilder builder;
  final OnvifResponseParser parser;
  final ErrorMapper errorMapper;
  final Duration timeout;
  final ClockContract clock;
  final HttpClient Function() _clientFactory;

  /// POSTs [body] to [service] and returns the response text. A SOAP fault
  /// comes back with an HTTP error status but is still returned as text so the
  /// parser can classify it; only a missing answer or a login rejection by the
  /// transport itself is an error here.
  Future<Result<String>> post(
    Uri service,
    String body, {
    CameraCredentials credentials = CameraCredentials.none,
  }) async {
    final HttpClient client = _clientFactory()..connectionTimeout = timeout;
    answerChallengeOnce(client, credentials);
    try {
      final HttpClientRequest request = await client.postUrl(service).timeout(timeout);
      request.headers.contentType =
          ContentType('application', 'soap+xml', charset: 'utf-8');
      request.add(utf8.encode(body));
      final HttpClientResponse response = await request.close().timeout(timeout);
      final String text = await utf8.decodeStream(response).timeout(timeout);
      if (text.trim().isEmpty ||
          (response.statusCode >= 400 && !text.contains('Fault'))) {
        return Err<String>(errorMapper.fromStatus(response.statusCode));
      }
      return Ok<String>(text);
    } on AppError catch (error) {
      return Err<String>(error);
    } catch (error) {
      return Err<String>(errorMapper.fromException(error));
    } finally {
      client.close(force: true);
    }
  }

  Future<Result<T>> _call<T>(
    Uri service,
    String body,
    CameraCredentials credentials,
    Result<T> Function(String text) parse,
  ) async {
    final Result<String> reply = await post(service, body, credentials: credentials);
    final AppError? error = reply.errorOrNull;
    if (error != null) {
      return Err<T>(error);
    }
    return parse(reply.valueOrNull!);
  }

  /// Camera clock minus ours. Needs no login.
  Future<Result<Duration>> clockOffset(Uri deviceService) {
    return _call<Duration>(
      deviceService,
      builder.getSystemDateAndTime(),
      CameraCredentials.none,
      (String text) => parser.parseTimeOffset(
        text,
        nowUtc: clock.now().toUtc(),
      ),
    );
  }

  Future<Result<OnvifDeviceInfo>> deviceInfo(
    Uri deviceService,
    CameraCredentials credentials, {
    Duration clockOffset = Duration.zero,
  }) {
    return _call<OnvifDeviceInfo>(
      deviceService,
      builder.getDeviceInformation(auth: OnvifAuth(credentials, timeOffset: clockOffset)),
      credentials,
      parser.parseDeviceInformation,
    );
  }

  Future<Result<OnvifServices>> services(
    Uri deviceService,
    CameraCredentials credentials, {
    Duration clockOffset = Duration.zero,
  }) {
    return _call<OnvifServices>(
      deviceService,
      builder.getCapabilities(auth: OnvifAuth(credentials, timeOffset: clockOffset)),
      credentials,
      parser.parseServices,
    );
  }

  Future<Result<List<OnvifProfile>>> profiles(
    Uri mediaService,
    CameraCredentials credentials, {
    Duration clockOffset = Duration.zero,
  }) {
    return _call<List<OnvifProfile>>(
      mediaService,
      builder.getProfiles(auth: OnvifAuth(credentials, timeOffset: clockOffset)),
      credentials,
      parser.parseProfiles,
    );
  }

  Future<Result<Uri>> streamUri(
    Uri mediaService,
    String profileToken,
    CameraCredentials credentials, {
    Duration clockOffset = Duration.zero,
  }) {
    return _call<Uri>(
      mediaService,
      builder.getStreamUri(
        profileToken,
        auth: OnvifAuth(credentials, timeOffset: clockOffset),
      ),
      credentials,
      parser.parseStreamUri,
    );
  }

  /// Sends one PTZ command to the camera's PTZ service.
  Future<Result<void>> ptz(
    Uri ptzService,
    String profileToken,
    PtzCommand command,
    CameraCredentials credentials, {
    Duration clockOffset = Duration.zero,
  }) {
    return _call<void>(
      ptzService,
      builder.ptzRequest(
        command,
        profileToken,
        auth: OnvifAuth(credentials, timeOffset: clockOffset),
      ),
      credentials,
      parser.parseAcknowledgement,
    );
  }

  /// Learns the camera's clock, its services and its profiles in one go. A
  /// camera that does not report its services is assumed to serve everything at
  /// [deviceService]. Cameras often advertise an internal address for their
  /// services; the host of [deviceService], the address we reached, replaces it.
  Future<Result<OnvifDevice>> connect(
    Uri deviceService,
    CameraCredentials credentials,
  ) async {
    final Duration offset =
        (await clockOffset(deviceService)).valueOrNull ?? Duration.zero;

    final Result<OnvifDeviceInfo> info =
        await deviceInfo(deviceService, credentials, clockOffset: offset);
    if (info.errorOrNull != null) {
      return Err<OnvifDevice>(info.errorOrNull!);
    }

    final OnvifServices services = (await this.services(
              deviceService,
              credentials,
              clockOffset: offset,
            ))
            .valueOrNull ??
        const OnvifServices();
    final Uri media = _reachable(services.media, deviceService);
    final Uri? ptz = services.ptz == null ? null : _reachable(services.ptz, deviceService);

    final Result<List<OnvifProfile>> profiles =
        await this.profiles(media, credentials, clockOffset: offset);
    if (profiles.errorOrNull != null) {
      return Err<OnvifDevice>(profiles.errorOrNull!);
    }
    if (profiles.valueOrNull!.isEmpty) {
      return const Err<OnvifDevice>(
        AppError(ErrorClass.unsupportedMedia, detail: 'camera reports no profiles'),
      );
    }
    return Ok<OnvifDevice>(
      OnvifDevice(
        deviceService: deviceService,
        info: info.valueOrNull!,
        profiles: profiles.valueOrNull!,
        mediaService: media,
        ptzService: ptz,
        clockOffset: offset,
      ),
    );
  }

  /// [advertised] with the host we actually reached; [deviceService] itself when
  /// nothing was advertised.
  static Uri _reachable(Uri? advertised, Uri deviceService) {
    if (advertised == null) {
      return deviceService;
    }
    if (advertised.host == deviceService.host) {
      return advertised;
    }
    return advertised.replace(host: deviceService.host);
  }
}
