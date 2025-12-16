// Firebase configuration options generated from google-services.json and GoogleService-Info.plist
// For production, use `flutterfire configure` to regenerate this file

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not configured for this project.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS is not configured for this project.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows is not configured for this project.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux is not configured for this project.',
        );
      default:
        throw UnsupportedError(
          'Platform not supported.',
        );
    }
  }

  // Android configuration from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDne_Gt_cg_o3hjYPI34VPyTFUt7eEfAVI',
    appId: '1:600108240234:android:676cad74962665adebe913',
    messagingSenderId: '600108240234',
    projectId: 'mininspire-57df3',
    storageBucket: 'mininspire-57df3.firebasestorage.app',
  );

  // iOS configuration from GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDkq2aNEJ9dOL_uAP0i1D-lMK8gG8XGK54',
    appId: '1:600108240234:ios:6eca666bcf85a45febe913',
    messagingSenderId: '600108240234',
    projectId: 'mininspire-57df3',
    storageBucket: 'mininspire-57df3.firebasestorage.app',
    iosBundleId: 'com.lesogs.minispire',
  );
}
