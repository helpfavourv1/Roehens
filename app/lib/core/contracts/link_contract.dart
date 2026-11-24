/// Opens something outside the app. Only mail is needed: Help and Settings
/// contain no outbound web links (D10).
abstract interface class LinkContract {
  /// Opens the person's mail app with a new message. False when no mail app
  /// could be opened.
  Future<bool> composeMail({
    required String to,
    required String subject,
    String body = '',
  });
}
