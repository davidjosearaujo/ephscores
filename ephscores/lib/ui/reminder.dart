import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../format.dart';
import '../patient/patient.dart';
import 'widgets.dart';

/// Vibrates and shows a message when it is time to re-assess the open
/// patient, as set on the dashboard. A single timer is set from the last
/// evaluation, so nothing ticks meanwhile. It only works while the app is
/// open: there is no notification permission.
class ReassessmentReminder extends StatefulWidget {
  const ReassessmentReminder({super.key});

  @override
  State<ReassessmentReminder> createState() => _ReassessmentReminderState();
}

class _ReassessmentReminderState extends State<ReassessmentReminder> {
  late final PatientStore _patient = AppScope.of(context).patient;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _patient.addListener(_schedule);
    _schedule();
  }

  @override
  void dispose() {
    _patient.removeListener(_schedule);
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    final minutes = _patient.reminderMinutes;
    if (!_patient.isActive || minutes == null) return;
    final interval = Duration(minutes: minutes);
    final since = DateTime.now().difference(_patient.evaluationStartedAt);
    // Past due (the app was closed): next multiple of the interval.
    final wait = since < interval
        ? interval - since
        : interval -
              Duration(
                microseconds: since.inMicroseconds % interval.inMicroseconds,
              );
    _timer = Timer(wait, _remind);
  }

  void _remind() {
    if (!mounted || !_patient.isActive) return;
    HapticFeedback.heavyImpact();
    final since = DateTime.now().difference(_patient.evaluationStartedAt);
    showToast(
      context,
      'Reavaliar o doente: ${formatDuration(since)} desde a última avaliação',
      duration: const Duration(seconds: 10),
    );
    // Again after another interval, if nothing is registered meanwhile.
    _schedule();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
