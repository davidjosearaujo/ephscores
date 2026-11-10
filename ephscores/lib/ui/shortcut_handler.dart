import 'package:flutter/material.dart';

import '../app.dart';
import '../platform/android.dart';
import 'contacts_page.dart';
import 'cpr_page.dart';
import 'start_page.dart';
import 'widgets.dart';

/// Acts on the launcher shortcuts: from a cold start and while running.
/// "Novo doente" never replaces a patient that is open; "PCR" opens one if
/// there is none and starts the resuscitation.
class ShortcutHandler extends StatefulWidget {
  const ShortcutHandler({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<ShortcutHandler> createState() => _ShortcutHandlerState();
}

class _ShortcutHandlerState extends State<ShortcutHandler> {
  @override
  void initState() {
    super.initState();
    listenForShortcuts(_run);
    launchShortcut().then((s) {
      if (s != null && mounted) _run(s);
    });
  }

  void _run(AppShortcut shortcut) {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    final scope = AppScope.of(context);
    final patient = scope.patient;
    switch (shortcut) {
      case AppShortcut.cpr:
        navigator.popUntil((r) => r.isFirst);
        beginCpr(navigator);
      case AppShortcut.newPatient:
        // Only from the start screen's state: a patient in progress stays,
        // and a finished one that nothing else keeps is not thrown away.
        if (patient.isActive) return;
        if (patient.isFinished && !scope.history.available) return;
        navigator.popUntil((r) => r.isFirst);
        scope.startPatient();
      case AppShortcut.start:
        navigator.popUntil((r) => r.isFirst);
        pushPage(navigator.context, const StartPage());
      case AppShortcut.contacts:
        navigator.popUntil((r) => r.isFirst);
        pushPage(navigator.context, const ContactsPage());
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
