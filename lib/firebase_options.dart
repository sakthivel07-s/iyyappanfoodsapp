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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCftv06Th1jfNeQH-8KdPB50dkpKWBymIA',
    appId: '1:105265930770:web:a1921a5c4d5ed705f82ecb',
    messagingSenderId: '105265930770',
    projectId: 'iyyappanfoods-app',
    authDomain: 'iyyappanfoods-app.firebaseapp.com',
    storageBucket: 'iyyappanfoods-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGhSlqGhA3I3fpig7qsf2NM983TlTls5Y',
    appId: '1:105265930770:android:1f3c21eff1c9f763f82ecb',
    messagingSenderId: '105265930770',
    projectId: 'iyyappanfoods-app',
    storageBucket: 'iyyappanfoods-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyATJnEobkSjP1q5D-THJhWoDsMo675W4nc',
    appId: '1:105265930770:ios:b7185f9c73015054f82ecb',
    messagingSenderId: '105265930770',
    projectId: 'iyyappanfoods-app',
    storageBucket: 'iyyappanfoods-app.firebasestorage.app',
    iosBundleId: 'com.iyyappan.foods',
  );
}
