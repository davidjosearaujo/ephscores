import 'android.dart';

/// Gets the sound ready; nothing to do on Android.
Future<void> prepareClick() async {}

/// A short beep, at the media volume.
void playClick() => androidClick();
