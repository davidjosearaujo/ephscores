import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@visibleForTesting
const secureScreenChannel = MethodChannel('ephscores/secure');

/// Blocks (or allows again) screenshots, screen recording and the
/// recent-apps thumbnail on Android. Does nothing elsewhere.
Future<void> setSecureScreen(bool secure) async {
  if (kIsWeb) return;
  try {
    await secureScreenChannel.invokeMethod<void>('setSecure', secure);
  } on MissingPluginException {
    // Not Android (or a test without the channel).
  }
}
