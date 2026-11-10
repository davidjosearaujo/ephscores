/// The click of the CPR metronome. Android plays a tone through its audio
/// system; the web app (iPhone, desktop) synthesises one with Web Audio, so
/// no sound file or audio plugin is needed.
library;

export 'click_native.dart' if (dart.library.js_interop) 'click_web.dart';
