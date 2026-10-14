// Firebase yapılandırması; değerler Firebase konsolundan indirilen
// `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS)
// dosyalarından alınmıştır. Proje: biromur-d0006.
//
// Bu anahtarlar istemci anahtarlarıdır ve uygulamanın içinde zaten bulunur;
// Google Cloud konsolunda paket adı ve bundle ID ile kısıtlanmaları önerilir.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
    TargetPlatform.android => android,
    TargetPlatform.iOS => ios,
    _ => throw UnsupportedError('Bir Ömür yalnızca Android ve iOS hedefler'),
  };

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCXccR6SUuSf0mNrCXoRAle9FQ0da7EFLQ',
    appId: '1:954783681198:android:1c704ca25127e783863b3f',
    messagingSenderId: '954783681198',
    projectId: 'biromur-d0006',
    storageBucket: 'biromur-d0006.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCTRjeSTjLu2yCt89QRFGQKtLO8pNaFp5M',
    appId: '1:954783681198:ios:7a00cb46b820d45f863b3f',
    messagingSenderId: '954783681198',
    projectId: 'biromur-d0006',
    storageBucket: 'biromur-d0006.firebasestorage.app',
    iosBundleId: 'com.zeysoft.biromur',
  );
}
