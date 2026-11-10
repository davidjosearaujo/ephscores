/// What only the Android shell can do, over one platform channel: window
/// flags, the metronome click, gesture exclusion and the launcher shortcuts. Everywhere else
/// these do nothing.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@visibleForTesting
const androidChannel = MethodChannel('ephscores/android');

Future<void> _flag(String method, bool on) async {
  if (kIsWeb) return;
  try {
    await androidChannel.invokeMethod<void>(method, on);
  } on MissingPluginException {
    // Not Android (or a test without the channel).
  }
}

/// Blocks (or allows again) screenshots, screen recording and the
/// recent-apps thumbnail. Android only.
Future<void> setSecureScreen(bool secure) => _flag('setSecure', secure);

/// Keeps the screen from turning off, e.g. while the team's hands are busy
/// with a birth. Android only.
Future<void> keepScreenOn(bool on) => _flag('keepScreenOn', on);

/// One short beep, for the CPR metronome. Android only.
Future<void> androidClick() async {
  if (kIsWeb) return;
  try {
    await androidChannel.invokeMethod<void>('click');
  } on MissingPluginException {
    // Not Android (or a test without the channel).
  }
}

/// Keeps the system's back swipe from the screen edge off [area] (in
/// physical pixels), so a tab there can be dragged; null puts it back.
/// Android 10 and later.
Future<void> excludeFromBackGesture(Rect? area) async {
  if (kIsWeb) return;
  try {
    await androidChannel.invokeMethod<void>('excludeGestures', [
      if (area != null) ...[
        area.left.round(),
        area.top.round(),
        area.right.round(),
        area.bottom.round(),
      ],
    ]);
  } on MissingPluginException {
    // Not Android (or a test without the channel).
  }
}

/// What a long press on the app icon offers.
enum AppShortcut {
  cpr('cpr'),
  newPatient('new_patient'),
  start('start'),
  contacts('contacts');

  const AppShortcut(this.id);

  final String id;

  static AppShortcut? byId(Object? id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// The shortcut the app was launched with, once; null when it was opened
/// normally.
Future<AppShortcut?> launchShortcut() async {
  if (kIsWeb) return null;
  try {
    return AppShortcut.byId(
      await androidChannel.invokeMethod<String>('takeShortcut'),
    );
  } on MissingPluginException {
    return null;
  }
}

/// Calls [onShortcut] when a shortcut is used while the app is running.
void listenForShortcuts(void Function(AppShortcut shortcut) onShortcut) {
  if (kIsWeb) return;
  androidChannel.setMethodCallHandler((call) async {
    final shortcut = AppShortcut.byId(call.arguments);
    if (call.method == 'shortcut' && shortcut != null) onShortcut(shortcut);
  });
}
