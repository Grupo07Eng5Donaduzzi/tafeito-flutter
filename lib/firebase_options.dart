import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBzu9ruKh4hkq-IYG2OXLVQ2it4IjoI1wE',
    authDomain: 'teste-901ff.firebaseapp.com',
    projectId: 'teste-901ff',
    storageBucket: 'teste-901ff.firebasestorage.app',
    messagingSenderId: '874743544455',
    appId: '1:874743544455:web:04107879de91664ed89622',
    measurementId: 'G-HQQTFBHW7G',
  );
}
