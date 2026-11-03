import 'package:flutter/material.dart';

import '../app.dart';
import 'dashboard_page.dart';
import 'welcome_page.dart';

/// The dashboard while a patient is open, otherwise the start screen.
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final patient = AppScope.of(context).patient;
    return ListenableBuilder(
      listenable: patient,
      builder: (context, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: patient.isActive
            ? const DashboardPage(key: ValueKey('dashboard'))
            : const WelcomePage(key: ValueKey('welcome')),
      ),
    );
  }
}
