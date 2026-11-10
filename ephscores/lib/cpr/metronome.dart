import 'dart:async';

import 'package:flutter/foundation.dart';

import '../platform/click.dart';
import 'cpr.dart';

/// Beats at a steady rate to pace chest compressions: a click for each
/// beat, and [flash] for a visual cue that lights up with it.
class Metronome extends ChangeNotifier {
  /// [onBeat] is the sound of each beat; tests pass their own.
  Metronome({VoidCallback? onBeat}) : _onBeat = onBeat ?? playClick;

  final VoidCallback _onBeat;

  int _rate = cprDefaultRate;
  bool _running = false;
  bool _flash = false;
  Timer? _timer;
  Timer? _flashOff;

  /// Beats per minute.
  int get rate => _rate;
  bool get running => _running;

  /// True for a moment after each beat.
  bool get flash => _flash;

  Duration get _period => Duration(microseconds: 60000000 ~/ _rate);

  /// Starts beating, with the first beat now. Call it from a tap: the web
  /// only lets a page make sound after one.
  void start() {
    if (_running) return;
    prepareClick();
    _running = true;
    _beat();
    _startTimer();
  }

  void stop() {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _flashOff?.cancel();
    _flash = false;
    notifyListeners();
  }

  void toggle() => _running ? stop() : start();

  /// Changes the rate within the range of the guidelines; the beat that
  /// follows comes one new period later.
  set rate(int value) {
    final next = value.clamp(cprMinRate, cprMaxRate);
    if (next == _rate) return;
    _rate = next;
    if (_running) _startTimer();
    notifyListeners();
  }

  /// Beats every period from now. Periodic timers keep time without
  /// drifting: each beat is placed from the one before, not from when the
  /// callback ran.
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_period, (_) => _beat());
  }

  void _beat() {
    _onBeat();
    _flash = true;
    _flashOff?.cancel();
    _flashOff = Timer(const Duration(milliseconds: 120), () {
      _flash = false;
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashOff?.cancel();
    super.dispose();
  }
}
