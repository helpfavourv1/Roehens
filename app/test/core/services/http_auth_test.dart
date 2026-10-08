import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/services/http_auth.dart';

void main() {
  const String challengeHeader =
      'Digest realm="testrealm@host.com", qop="auth,auth-int", '
      'nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", '
      'opaque="5ccc069c403ebaf9f0171e9517f40e41"';

  group('challenge', () {
    test('is parsed from the header', () {
      final DigestChallenge challenge = DigestChallenge.parse(challengeHeader)!;
      expect(challenge.realm, 'testrealm@host.com');
      expect(challenge.nonce, 'dcd98b7102dd2f0e8b11d0f600bfb0c093');
      expect(challenge.qop, 'auth,auth-int');
      expect(challenge.opaque, '5ccc069c403ebaf9f0171e9517f40e41');
    });

    test('unquoted values and any letter case are accepted', () {
      final DigestChallenge challenge = DigestChallenge.parse(
        'digest REALM=cam, nonce=abc, algorithm=MD5',
      )!;
      expect(challenge.realm, 'cam');
      expect(challenge.nonce, 'abc');
      expect(challenge.qop, isNull);
    });

    test('anything else is not a challenge', () {
      expect(DigestChallenge.parse('Basic realm="x"'), isNull);
      expect(DigestChallenge.parse('Digest realm="x"'), isNull); // no nonce
      expect(DigestChallenge.parse(''), isNull);
    });
  });

  group('digest response', () {
    test('matches the RFC 2617 example', () {
      final String header = HttpAuth.digest(
        challenge: DigestChallenge.parse(challengeHeader)!,
        method: 'GET',
        uri: '/dir/index.html',
        username: 'Mufasa',
        password: 'Circle Of Life',
        cnonce: '0a4f113b',
      );
      expect(header, contains('response="6629fae49393a05397450978507c4ef1"'));
      expect(header, contains('qop=auth'));
      expect(header, contains('nc=00000001'));
      expect(header, contains('cnonce="0a4f113b"'));
      expect(header, contains('username="Mufasa"'));
      expect(header, contains('uri="/dir/index.html"'));
      expect(header, contains('opaque="5ccc069c403ebaf9f0171e9517f40e41"'));
    });

    test('without qop the older RFC 2069 form is used', () {
      final String header = HttpAuth.digest(
        challenge: const DigestChallenge(
          realm: 'testrealm@host.com',
          nonce: 'dcd98b7102dd2f0e8b11d0f600bfb0c093',
        ),
        method: 'GET',
        uri: '/dir/index.html',
        username: 'Mufasa',
        password: 'Circle Of Life',
      );
      expect(header, contains('response="670fd8c2df070c60b045671b8b24ff02"'));
      expect(header.contains('cnonce'), isFalse);
      expect(header.contains('qop='), isFalse);
    });

    test('the nonce count is counted in hex with eight digits', () {
      final String header = HttpAuth.digest(
        challenge: DigestChallenge.parse(challengeHeader)!,
        method: 'GET',
        uri: '/',
        username: 'u',
        password: 'p',
        cnonce: 'abcd',
        nonceCount: 26,
      );
      expect(header, contains('nc=0000001a'));
    });

    test('a random client nonce differs between calls', () {
      String once() => HttpAuth.digest(
            challenge: DigestChallenge.parse(challengeHeader)!,
            method: 'GET',
            uri: '/',
            username: 'u',
            password: 'p',
          );
      expect(once(), isNot(once()));
    });
  });

  group('basic', () {
    test('encodes user and password', () {
      expect(HttpAuth.basic('admin', 'pw12345'), 'Basic YWRtaW46cHcxMjM0NQ==');
    });
  });

  group('answer', () {
    test('prefers Digest over Basic', () {
      final String? header = HttpAuth.answer(
        headers: <String>['Basic realm="cam"', challengeHeader],
        method: 'DESCRIBE',
        uri: 'rtsp://cam/s',
        username: 'u',
        password: 'p',
      );
      expect(header, startsWith('Digest '));
    });

    test('falls back to Basic', () {
      expect(
        HttpAuth.answer(
          headers: <String>['Basic realm="cam"'],
          method: 'GET',
          uri: '/',
          username: 'admin',
          password: 'pw12345',
        ),
        'Basic YWRtaW46cHcxMjM0NQ==',
      );
    });

    test('offers nothing when the server asks for something else', () {
      expect(
        HttpAuth.answer(
          headers: <String>['Bearer realm="x"'],
          method: 'GET',
          uri: '/',
          username: 'u',
          password: 'p',
        ),
        isNull,
      );
      expect(
        HttpAuth.answer(
          headers: const <String>[],
          method: 'GET',
          uri: '/',
          username: 'u',
          password: 'p',
        ),
        isNull,
      );
    });
  });
}
