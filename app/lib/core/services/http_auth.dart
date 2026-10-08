import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A parsed `WWW-Authenticate: Digest ...` challenge.
class DigestChallenge {
  const DigestChallenge({
    required this.realm,
    required this.nonce,
    this.qop,
    this.opaque,
  });

  final String realm;
  final String nonce;

  /// Quality of protection offered, for example `auth` or `auth,auth-int`.
  final String? qop;
  final String? opaque;

  /// Reads a Digest challenge, or returns null when [header] is not one.
  static DigestChallenge? parse(String header) {
    final String trimmed = header.trim();
    if (!trimmed.toLowerCase().startsWith('digest ')) {
      return null;
    }
    final Map<String, String> fields = <String, String>{};
    for (final RegExpMatch match in RegExp(r'(\w+)\s*=\s*(?:"([^"]*)"|([^,\s]+))')
        .allMatches(trimmed.substring(7))) {
      fields[match.group(1)!.toLowerCase()] = match.group(2) ?? match.group(3)!;
    }
    final String? realm = fields['realm'];
    final String? nonce = fields['nonce'];
    if (realm == null || nonce == null) {
      return null;
    }
    return DigestChallenge(
      realm: realm,
      nonce: nonce,
      qop: fields['qop'],
      opaque: fields['opaque'],
    );
  }
}

/// `Authorization` header values for HTTP and RTSP (RFC 2617).
class HttpAuth {
  HttpAuth._();

  static String basic(String username, String password) {
    return 'Basic ${base64.encode(utf8.encode('$username:$password'))}';
  }

  static String _md5(String text) => md5.convert(utf8.encode(text)).toString();

  static String _randomHex(int bytes) {
    final Random random = Random.secure();
    return List<int>.generate(bytes, (int _) => random.nextInt(256))
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// The Digest response for [method] and [uri]. [cnonce] and [nonceCount] exist
  /// so tests can fix them.
  static String digest({
    required DigestChallenge challenge,
    required String method,
    required String uri,
    required String username,
    required String password,
    String? cnonce,
    int nonceCount = 1,
  }) {
    final String ha1 = _md5('$username:${challenge.realm}:$password');
    final String ha2 = _md5('$method:$uri');
    final bool useQop = (challenge.qop ?? '')
        .split(',')
        .map((String q) => q.trim())
        .contains('auth');
    final String nc = nonceCount.toRadixString(16).padLeft(8, '0');
    final String clientNonce = cnonce ?? _randomHex(8);
    final String response = useQop
        ? _md5('$ha1:${challenge.nonce}:$nc:$clientNonce:auth:$ha2')
        : _md5('$ha1:${challenge.nonce}:$ha2');

    final StringBuffer header = StringBuffer('Digest ')
      ..write('username="$username", realm="${challenge.realm}", ')
      ..write('nonce="${challenge.nonce}", uri="$uri", ')
      ..write('response="$response"');
    if (useQop) {
      header.write(', qop=auth, nc=$nc, cnonce="$clientNonce"');
    }
    if (challenge.opaque != null) {
      header.write(', opaque="${challenge.opaque}"');
    }
    header.write(', algorithm=MD5');
    return header.toString();
  }

  /// The best `Authorization` value for the challenges in [headers] (every
  /// `WWW-Authenticate` value), preferring Digest over Basic. Null when the
  /// server offers neither.
  static String? answer({
    required List<String> headers,
    required String method,
    required String uri,
    required String username,
    required String password,
  }) {
    for (final String header in headers) {
      final DigestChallenge? challenge = DigestChallenge.parse(header);
      if (challenge != null) {
        return digest(
          challenge: challenge,
          method: method,
          uri: uri,
          username: username,
          password: password,
        );
      }
    }
    if (headers.any((String h) => h.trim().toLowerCase().startsWith('basic'))) {
      return basic(username, password);
    }
    return null;
  }
}
