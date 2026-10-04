/// Asks the store to show its rating prompt.
abstract interface class ReviewContract {
  Future<bool> get isAvailable;

  /// Requests the in-app review flow; the store decides whether it shows.
  Future<void> requestReview();

  /// Opens the store listing, for an explicit "Rate" action in Settings.
  Future<void> openStoreListing();
}
