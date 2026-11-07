import 'package:flutter/material.dart';

import '../app.dart';
import '../format.dart';
import '../patient/patient.dart';
import '../theme.dart';
import 'via_verde_page.dart' show resolveClockTime;
import 'widgets.dart';

/// Counts the dialogs and sheets open on the navigator, so the tab can
/// step aside while one is shown.
class PopupTracker extends NavigatorObserver {
  final open = ValueNotifier<int>(0);

  void _change(Route<dynamic>? route, int by) {
    if (route is PopupRoute) open.value = (open.value + by).clamp(0, 99);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _change(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _change(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _change(route, -1);
}

/// A small tab hanging from the top of every page while a patient is open,
/// with an arrow pointing down: tap it or pull it down to open the
/// occurrence times. It sits above the page titles (the app bars are tall
/// enough for it), with a larger touch area for gloved hands.
class EventsTab extends StatelessWidget {
  const EventsTab({
    super.key,
    required this.navigatorKey,
    required this.popups,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final PopupTracker popups;

  void _open() {
    final context = navigatorKey.currentContext;
    if (context != null) showEventsPanel(context);
  }

  @override
  Widget build(BuildContext context) {
    final patient = AppScope.of(context).patient;
    return ListenableBuilder(
      listenable: Listenable.merge([patient, popups.open]),
      builder: (context, _) {
        if (!patient.isActive || popups.open.value > 0) {
          return const SizedBox.shrink();
        }
        final count = patient.events.length;
        // Right of centre, clear of the front camera that most phones have
        // in the middle, and left of the app bar actions.
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top,
              right: 60,
            ),
            child: Semantics(
              container: true,
              button: true,
              label: 'Horas da ocorrência, $count registadas',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _open,
                // Any pull downwards opens it.
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) >= 0) _open();
                },
                child: SizedBox(
                  width: 116,
                  height: 44,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _Tab(count: count),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Palette.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
        border: Border(
          left: BorderSide(color: fg, width: 1.5),
          right: BorderSide(color: fg, width: 1.5),
          bottom: BorderSide(color: fg, width: 1.5),
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      // Above the navigator there is no Material to style the text.
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 15, color: fg),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Palette.amber,
                ),
              ),
            ],
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: fg),
          ],
        ),
      ),
    );
  }
}

/// The occurrence times, sliding down from the top of the screen. Swipe it
/// up, tap outside or use the close button to put it away.
Future<void> showEventsPanel(BuildContext context) => showGeneralDialog(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Fechar',
  barrierColor: Colors.black54,
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (context, _, _) => const EventsPanel(),
  transitionBuilder: (context, animation, _, child) => SlideTransition(
    position: Tween(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  ),
);

class EventsPanel extends StatelessWidget {
  const EventsPanel({super.key});

  Future<void> _edit(
    BuildContext context,
    PatientStore patient,
    PatientEvent event,
    DateTime current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: event.label,
    );
    if (picked != null) {
      patient.setEvent(event, resolveClockTime(picked, DateTime.now()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final patient = AppScope.of(context).patient;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: GestureDetector(
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < -200) Navigator.pop(context);
          },
          child: Material(
            color: scheme.pageBackground,
            elevation: 8,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            child: SafeArea(
              bottom: false,
              child: ListenableBuilder(
                listenable: patient,
                builder: (context, _) {
                  final events = patient.events;
                  // The list takes vertical drags, so an upward swipe shows
                  // up as an overscroll past its end: that closes it.
                  return NotificationListener<OverscrollNotification>(
                    onNotification: (n) {
                      if (n.dragDetails != null &&
                          n.overscroll > 6 &&
                          ModalRoute.of(context)?.isCurrent == true) {
                        Navigator.pop(context);
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, color: scheme.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Horas da ocorrência',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Fechar',
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          Text(
                            'Toque para registar a hora atual; toque numa hora '
                            'registada para a alterar.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final event in PatientEvent.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _EventTile(
                                event: event,
                                at: events[event],
                                onStamp: () =>
                                    patient.setEvent(event, DateTime.now()),
                                onEdit: () => _edit(
                                  context,
                                  patient,
                                  event,
                                  events[event]!,
                                ),
                                onClear: () => patient.setEvent(event, null),
                              ),
                            ),
                          // Grabber: a cue that the panel slides back up.
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: scheme.outline,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.at,
    required this.onStamp,
    required this.onEdit,
    required this.onClear,
  });

  final PatientEvent event;
  final DateTime? at;
  final VoidCallback onStamp;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final at = this.at;
    return SelectableTile(
      selected: at != null,
      onTap: at == null ? onStamp : onEdit,
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      builder: (fg) => Row(
        children: [
          Expanded(
            child: Text(
              event.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
          ),
          if (at == null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                'Registar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
            )
          else ...[
            Text(
              formatClock(at),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            IconButton(
              tooltip: 'Limpar ${event.label}',
              color: fg,
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          ],
        ],
      ),
    );
  }
}
