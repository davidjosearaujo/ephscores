import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@visibleForTesting
const windowChannel = MethodChannel('ephscores/window');

Future<void> _set(String method, bool on) async {
  if (kIsWeb) return;
  try {
    await windowChannel.invokeMethod<void>(method, on);
  } on MissingPluginException {
    // Not Android (or a test without the channel).
  }
}

/// Blocks (or allows again) screenshots, screen recording and the
/// recent-apps thumbnail on Android. Does nothing elsewhere.
Future<void> setSecureScreen(bool secure) => _set('setSecure', secure);

/// Keeps the screen from turning off, e.g. while the team's hands are busy
/// with a birth. Android only.
Future<void> keepScreenOn(bool on) => _set('keepScreenOn', on);
