import 'dart:io';

import 'package:roehens/core/models/camera.dart';

/// Lets [client] answer a camera's Basic or Digest login challenge with
/// [credentials], once.
///
/// Answering only once matters: when the credentials are wrong, Dart's client
/// otherwise keeps retrying them until the request times out, and the person
/// sees "cannot reach the camera" instead of "check username or password".
/// After one failed answer the 401 response is returned as it is.
void answerChallengeOnce(HttpClient client, CameraCredentials credentials) {
  if (credentials.isEmpty) {
    return;
  }
  bool answered = false;
  client.authenticate = (Uri url, String scheme, String? realm) async {
    if (answered) {
      return false;
    }
    answered = true;
    client.addCredentials(
      url,
      realm ?? '',
      scheme.toLowerCase() == 'digest'
          ? HttpClientDigestCredentials(
              credentials.username,
              credentials.password,
            )
          : HttpClientBasicCredentials(
              credentials.username,
              credentials.password,
            ),
    );
    return true;
  };
}
