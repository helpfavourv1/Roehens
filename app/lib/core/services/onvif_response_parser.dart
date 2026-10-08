import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:xml/xml.dart';

/// What GetDeviceInformation reports.
class OnvifDeviceInfo {
  const OnvifDeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.firmwareVersion,
    required this.serialNumber,
    required this.hardwareId,
  });

  final String manufacturer;
  final String model;
  final String firmwareVersion;
  final String serialNumber;
  final String hardwareId;
}

/// One media profile of a camera.
class OnvifProfile {
  const OnvifProfile({
    required this.token,
    required this.name,
    this.videoEncoding,
    this.width,
    this.height,
    this.frameRateLimit,
    this.bitrateLimitKbps,
    this.hasPtz = false,
  });

  final String token;
  final String name;

  /// `H264`, `H265` or `JPEG`, as the camera spells it.
  final String? videoEncoding;
  final int? width;
  final int? height;
  final int? frameRateLimit;
  final int? bitrateLimitKbps;
  final bool hasPtz;

  /// Resolution in pixels, 0 when unknown. Used to tell main from substream.
  int get pixels => (width ?? 0) * (height ?? 0);
}

/// Where a device's other services live. Null when it does not offer one.
class OnvifServices {
  const OnvifServices({this.media, this.ptz});

  final Uri? media;
  final Uri? ptz;
}

/// The profile to use for the main stream (most pixels) and for the substream
/// (fewest pixels, only when it is clearly smaller).
({OnvifProfile? main, OnvifProfile? sub}) selectMainAndSub(
  List<OnvifProfile> profiles,
) {
  if (profiles.isEmpty) {
    return (main: null, sub: null);
  }
  OnvifProfile main = profiles.first;
  for (final OnvifProfile profile in profiles) {
    if (profile.pixels > main.pixels) {
      main = profile;
    }
  }
  OnvifProfile? sub;
  for (final OnvifProfile profile in profiles) {
    if (profile.token == main.token || profile.pixels >= main.pixels) {
      continue;
    }
    if (sub == null || profile.pixels < sub.pixels) {
      sub = profile;
    }
  }
  return (main: main, sub: sub);
}

/// Turns SOAP responses into values or classified errors. Never throws.
class OnvifResponseParser {
  const OnvifResponseParser();

  Result<OnvifDeviceInfo> parseDeviceInformation(String text) {
    return _parse<OnvifDeviceInfo>(text, (XmlElement root) {
      final XmlElement? response = _first(root, 'GetDeviceInformationResponse');
      if (response == null) {
        return _unexpected<OnvifDeviceInfo>();
      }
      return Ok<OnvifDeviceInfo>(
        OnvifDeviceInfo(
          manufacturer: _text(response, 'Manufacturer'),
          model: _text(response, 'Model'),
          firmwareVersion: _text(response, 'FirmwareVersion'),
          serialNumber: _text(response, 'SerialNumber'),
          hardwareId: _text(response, 'HardwareId'),
        ),
      );
    });
  }

  Result<OnvifServices> parseServices(String text) {
    return _parse<OnvifServices>(text, (XmlElement root) {
      final XmlElement? capabilities = _first(root, 'Capabilities');
      if (capabilities == null) {
        return _unexpected<OnvifServices>();
      }
      Uri? address(String service) {
        final XmlElement? element = _first(capabilities, service);
        final String text = element == null ? '' : _text(element, 'XAddr');
        final Uri? uri = Uri.tryParse(text);
        return uri == null || uri.host.isEmpty ? null : uri;
      }

      return Ok<OnvifServices>(
        OnvifServices(media: address('Media'), ptz: address('PTZ')),
      );
    });
  }

  Result<List<OnvifProfile>> parseProfiles(String text) {
    return _parse<List<OnvifProfile>>(text, (XmlElement root) {
      final XmlElement? response = _first(root, 'GetProfilesResponse');
      if (response == null) {
        return _unexpected<List<OnvifProfile>>();
      }
      final List<OnvifProfile> profiles = <OnvifProfile>[];
      for (final XmlElement element in response.childElements) {
        if (element.name.local != 'Profiles') {
          continue;
        }
        final String? token = element.getAttribute('token');
        if (token == null || token.isEmpty) {
          continue;
        }
        final XmlElement? video = _first(element, 'VideoEncoderConfiguration');
        profiles.add(
          OnvifProfile(
            token: token,
            name: _text(element, 'Name'),
            videoEncoding: video == null ? null : _nullable(_text(video, 'Encoding')),
            width: video == null ? null : int.tryParse(_text(video, 'Width')),
            height: video == null ? null : int.tryParse(_text(video, 'Height')),
            frameRateLimit:
                video == null ? null : int.tryParse(_text(video, 'FrameRateLimit')),
            bitrateLimitKbps:
                video == null ? null : int.tryParse(_text(video, 'BitrateLimit')),
            hasPtz: _first(element, 'PTZConfiguration') != null,
          ),
        );
      }
      return Ok<List<OnvifProfile>>(profiles);
    });
  }

  Result<Uri> parseStreamUri(String text) {
    return _parse<Uri>(text, (XmlElement root) {
      final XmlElement? media = _first(root, 'MediaUri');
      final Uri? uri = media == null ? null : Uri.tryParse(_text(media, 'Uri'));
      if (uri == null || uri.host.isEmpty) {
        return _unexpected<Uri>();
      }
      return Ok<Uri>(uri);
    });
  }

  /// How far the camera's clock is ahead of [nowUtc] (negative when behind).
  Result<Duration> parseTimeOffset(String text, {required DateTime nowUtc}) {
    return _parse<Duration>(text, (XmlElement root) {
      final XmlElement? utc = _first(root, 'UTCDateTime');
      if (utc == null) {
        return _unexpected<Duration>();
      }
      final int? year = int.tryParse(_text(utc, 'Year'));
      final int? month = int.tryParse(_text(utc, 'Month'));
      final int? day = int.tryParse(_text(utc, 'Day'));
      final int? hour = int.tryParse(_text(utc, 'Hour'));
      final int? minute = int.tryParse(_text(utc, 'Minute'));
      final int? second = int.tryParse(_text(utc, 'Second'));
      if (year == null ||
          month == null ||
          day == null ||
          hour == null ||
          minute == null ||
          second == null) {
        return _unexpected<Duration>();
      }
      return Ok<Duration>(
        DateTime.utc(year, month, day, hour, minute, second).difference(nowUtc),
      );
    });
  }

  /// For requests that return nothing useful (PTZ moves): ok unless the camera
  /// answered with a fault.
  Result<void> parseAcknowledgement(String text) {
    return _parse<void>(text, (XmlElement root) => const Ok<void>(null));
  }

  Result<T> _parse<T>(String text, Result<T> Function(XmlElement root) read) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(text);
    } on XmlException {
      return Err<T>(
        const AppError(
          ErrorClass.unsupportedMedia,
          detail: 'malformed ONVIF response',
        ),
      );
    }
    final XmlElement root = document.rootElement;
    final XmlElement? fault = _first(root, 'Fault');
    if (fault != null) {
      return Err<T>(_faultToError(fault));
    }
    return read(root);
  }

  static Result<T> _unexpected<T>() {
    return Err<T>(
      const AppError(
        ErrorClass.unsupportedMedia,
        detail: 'unexpected ONVIF response',
      ),
    );
  }

  static AppError _faultToError(XmlElement fault) {
    final String reason = _text(fault, 'Text');
    final String codes = fault.descendantElements
        .where((XmlElement e) => e.name.local == 'Value')
        .map((XmlElement e) => e.innerText.trim())
        .join(' ');
    final String all = '$codes $reason'.toLowerCase();
    final bool notAuthorized = all.contains('notauthorized') ||
        all.contains('not authorized') ||
        all.contains('unauthorized');
    return AppError(
      notAuthorized ? ErrorClass.authFailed : ErrorClass.unsupportedMedia,
      detail: 'ONVIF fault: ${reason.isEmpty ? codes : reason}',
    );
  }

  static XmlElement? _first(XmlElement root, String local) {
    if (root.name.local == local) {
      return root;
    }
    for (final XmlElement element in root.descendantElements) {
      if (element.name.local == local) {
        return element;
      }
    }
    return null;
  }

  static String _text(XmlElement root, String local) {
    return _first(root, local)?.innerText.trim() ?? '';
  }

  static String? _nullable(String text) => text.isEmpty ? null : text;
}
