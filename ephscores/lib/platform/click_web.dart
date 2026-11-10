import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.AudioContext? _context;

/// Creates and wakes the audio context. Browsers only allow sound after a
/// tap, so this must run from one (the metronome's start does).
Future<void> prepareClick() async {
  try {
    final context = _context ??= web.AudioContext();
    if (context.state == 'suspended') await context.resume().toDart;
  } on Object {
    // No Web Audio: the metronome stays silent but keeps its visual beat.
  }
}

/// A 50 ms beep that fades out quickly, so it doesn't click.
void playClick() {
  final context = _context;
  if (context == null || context.state != 'running') return;
  final now = context.currentTime;
  final oscillator = context.createOscillator()..frequency.value = 1200;
  final gain = context.createGain();
  gain.gain
    ..setValueAtTime(0.6, now)
    ..exponentialRampToValueAtTime(0.001, now + 0.05);
  oscillator
    ..connect(gain)
    ..start(now)
    ..stop(now + 0.06);
  gain.connect(context.destination);
}
