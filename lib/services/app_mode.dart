/// Whether the app is running against an on-device local store instead of
/// a real Firebase project. Set once in `main()` based on whether
/// `firebase_options.dart` still has placeholder credentials.
class AppMode {
  AppMode._();

  static bool useLocal = false;
}
