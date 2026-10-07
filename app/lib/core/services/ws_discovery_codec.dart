import 'package:roehens/core/models/discovery_result.dart';
import 'package:xml/xml.dart';

/// WS-Discovery messages for finding ONVIF devices: the Probe that is sent to
/// the multicast group, and the parser for the ProbeMatches that come back.
class WsDiscoveryCodec {
  const WsDiscoveryCodec();

  /// The Probe for network video transmitters. [messageId] is a UUID.
  String buildProbe({required String messageId}) {
    return '<?xml version="1.0" encoding="UTF-8"?>'
        '<e:Envelope xmlns:e="http://www.w3.org/2003/05/soap-envelope" '
        'xmlns:w="http://schemas.xmlsoap.org/ws/2004/08/addressing" '
        'xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" '
        'xmlns:dn="http://www.onvif.org/ver10/network/wsdl">'
        '<e:Header>'
        '<w:MessageID>uuid:$messageId</w:MessageID>'
        '<w:To e:mustUnderstand="true">'
        'urn:schemas-xmlsoap-org:ws:2005:04:discovery</w:To>'
        '<w:Action e:mustUnderstand="true">'
        'http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</w:Action>'
        '</e:Header>'
        '<e:Body><d:Probe><d:Types>dn:NetworkVideoTransmitter</d:Types>'
        '</d:Probe></e:Body></e:Envelope>';
  }

  /// Parses a reply datagram. Returns null when it is not a ProbeMatches
  /// message or carries no usable device address.
  DiscoveryResult? parseProbeMatch(String text) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(text);
    } on XmlException {
      return null;
    }
    final XmlElement? match = _first(document.rootElement, 'ProbeMatch');
    if (match == null) {
      return null;
    }
    final List<String> addresses = _words(_text(match, 'XAddrs'));
    final List<String> scopes = _words(_text(match, 'Scopes'));
    final Uri? chosen = _chooseAddress(addresses);
    if (chosen == null) {
      return null;
    }
    return DiscoveryResult(
      host: chosen.host,
      port: chosen.hasPort ? chosen.port : (chosen.scheme == 'https' ? 443 : 80),
      source: DiscoverySource.onvif,
      name: _scopeValue(scopes, 'name'),
      model: _scopeValue(scopes, 'hardware'),
      scopes: scopes,
      xaddrs: addresses,
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

  static List<String> _words(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
  }

  /// The first plain IPv4 address wins; otherwise the first usable one.
  static Uri? _chooseAddress(List<String> addresses) {
    final RegExp ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
    Uri? fallback;
    for (final String text in addresses) {
      final Uri? uri = Uri.tryParse(text);
      if (uri == null || uri.host.isEmpty) {
        continue;
      }
      if (ipv4.hasMatch(uri.host)) {
        return uri;
      }
      fallback ??= uri;
    }
    return fallback;
  }

  static String? _scopeValue(List<String> scopes, String key) {
    final String prefix = 'onvif://www.onvif.org/$key/';
    for (final String scope in scopes) {
      if (scope.startsWith(prefix) && scope.length > prefix.length) {
        final String raw = scope.substring(prefix.length);
        try {
          return Uri.decodeComponent(raw).replaceAll('_', ' ');
        } on FormatException {
          return raw;
        }
      }
    }
    return null;
  }
}
