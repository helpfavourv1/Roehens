import 'package:roehens/core/contracts/link_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the mail app through the system. Nothing is sent by Roehens itself.
class LinkService implements LinkContract {
  LinkService({required this._logger});

  final LoggerContract _logger;

  /// Mail apps cut very long addresses, so the body is limited.
  static const int maxBodyLength = 1800;

  @override
  Future<bool> composeMail({
    required String to,
    required String subject,
    String body = '',
  }) async {
    final String trimmed = body.length > maxBodyLength
        ? body.substring(0, maxBodyLength)
        : body;
    // Spaces must be %20 in a mailto link; Uri.queryParameters would use '+'.
    final Uri uri = Uri.parse(
      'mailto:$to?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(trimmed)}',
    );
    try {
      return await launchUrl(uri);
    } catch (error) {
      _logger.warning('link', 'could not open the mail app', error: error);
      return false;
    }
  }
}
