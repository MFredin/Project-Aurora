import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBuHA_cuDNTi0CNSiGYr_SK3cRflxi8iFw',
    appId: '1:344243876739:web:9b07b6d5fbe9cea2bcbcb6',
    messagingSenderId: '344243876739',
    projectId: 'edda-reader',
    authDomain: 'edda-reader.firebaseapp.com',
    storageBucket: 'edda-reader.firebasestorage.app',
    measurementId: 'G-0QLD07C31T',
  );

  // Placeholder — register an Android app in Firebase Console,
  // then replace these values with the ones from google-services.json.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuHA_cuDNTi0CNSiGYr_SK3cRflxi8iFw',
    appId: '1:344243876739:web:9b07b6d5fbe9cea2bcbcb6',
    messagingSenderId: '344243876739',
    projectId: 'edda-reader',
    storageBucket: 'edda-reader.firebasestorage.app',
  );

  // Placeholder — register an iOS app in Firebase Console,
  // then replace these values with the ones from GoogleService-Info.plist.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBuHA_cuDNTi0CNSiGYr_SK3cRflxi8iFw',
    appId: '1:344243876739:web:9b07b6d5fbe9cea2bcbcb6',
    messagingSenderId: '344243876739',
    projectId: 'edda-reader',
    storageBucket: 'edda-reader.firebasestorage.app',
    iosBundleId: 'com.edda.reader',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBuHA_cuDNTi0CNSiGYr_SK3cRflxi8iFw',
    appId: '1:344243876739:web:9b07b6d5fbe9cea2bcbcb6',
    messagingSenderId: '344243876739',
    projectId: 'edda-reader',
    storageBucket: 'edda-reader.firebasestorage.app',
    iosBundleId: 'com.edda.reader',
  );
}
