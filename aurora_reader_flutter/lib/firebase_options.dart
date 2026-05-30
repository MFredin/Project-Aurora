import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Placeholder Firebase configuration.
///
/// Replace this file by running the FlutterFire CLI:
///
///   dart pub global activate flutterfire_cli
///   flutterfire configure
///
/// This will generate real Firebase options for your project.
/// Until then, the app uses local authentication.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase has not been configured. '
      'Run `flutterfire configure` to generate firebase_options.dart.',
    );
  }
}
