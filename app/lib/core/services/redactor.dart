/// Removes secrets from text before it is stored or shared.
class Redactor {
  Redactor._();

  static final RegExp _urlCredentials =
      RegExp(r'([A-Za-z][A-Za-z0-9+.-]*://)[^/@\s]+:[^/@\s]+@');

  /// Masks `user:password@` in every URL inside [text].
  static String redactUrls(String text) {
    return text.replaceAllMapped(
      _urlCredentials,
      (Match m) => '${m.group(1)}***@',
    );
  }
}
