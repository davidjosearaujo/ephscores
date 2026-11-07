import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../format.dart';
import '../patient/patient.dart';
import '../theme.dart';
import 'widgets.dart';

/// Name of the route of the occurrence-times panel.
const _panelRoute = 'events';

/// Counts the dialogs and sheets open on the navigator, so the bubble can
/// step aside while one is shown, and tracks its own panel, which keeps the
/// bubble in view.
class PopupTracker extends NavigatorObserver {
  /// Dialogs other than the times panel.
  final open = ValueNotifier<int>(0);

  /// The times panel is showing.
  final panelOpen = ValueNotifier<bool>(false);

  void _change(Route<dynamic>? route, int by) {
    if (route is! PopupRoute) return;
    if (route.settings.name == _panelRoute) {
      panelOpen.value = by > 0;
    } else {
      open.value = (open.value + by).clamp(0, 99);
    }
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

/// A small floating bubble, on every page while a patient is open, that
/// opens the occurrence times in a speech bubble. It can be dragged to
/// either side so it never hides what is underneath, and steps aside while
/// typing or while a dialog is open. While its panel is open it moves to
/// the bottom of its side, so the whole panel fits above it.
class EventsBubble extends StatefulWidget {
  const EventsBubble({
    super.key,
    required this.navigatorKey,
    required this.popups,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final PopupTracker popups;

  static const size = 52.0;

  @override
  State<EventsBubble> createState() => _EventsBubbleState();
}

class _EventsBubbleState extends State<EventsBubble> {
  static const _margin = 8.0;

  /// Resting place: which side, and how far down (0 to 1).
  bool _right = true;
  double _y = 0.62;

  /// Free position while being dragged.
  Offset? _drag;

  /// Where the bubble goes while its panel is open: the bottom of its side,
  /// leaving the most room above for the whole panel. Set on each layout.
  Offset _dock = Offset.zero;

  final _stackKey = GlobalKey();

  void _toggle() {
    final navigator = widget.navigatorKey.currentState;
    if (widget.popups.panelOpen.value) {
      navigator?.pop();
      return;
    }
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = navigator?.overlay?.context.findRenderObject();
    if (navigator == null || stack == null || overlay == null) return;
    // Where the bubble is going, in the coordinates the panel is laid out
    // in: the panel grows out of it as it arrives.
    final anchor =
        stack.localToGlobal(_dock, ancestor: overlay) &
        const Size.square(EventsBubble.size);
    showEventsPanel(navigator.context, anchor);
  }

  @override
  Widget build(BuildContext context) {
    final patient = AppScope.of(context).patient;
    final popups = widget.popups;
    return ListenableBuilder(
      listenable: Listenable.merge([patient, popups.open, popups.panelOpen]),
      builder: (context, _) {
        if (!patient.isActive ||
            popups.open.value > 0 ||
            MediaQuery.viewInsetsOf(context).bottom > 0) {
          return const SizedBox.shrink();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            const s = EventsBubble.size;
            final pad = MediaQuery.paddingOf(context);
            final w = constraints.maxWidth, h = constraints.maxHeight;
            final minY = pad.top + _margin;
            final maxY = h - pad.bottom - s - _margin;
            final x = _right ? w - s - _margin : _margin;
            final rest = Offset(x, (_y * h).clamp(minY, maxY));
            _dock = Offset(x, maxY);
            final at = _drag ?? (popups.panelOpen.value ? _dock : rest);
            return Stack(
              key: _stackKey,
              children: [
                AnimatedPositioned(
                  // Follows the finger while dragged; glides otherwise.
                  duration: _drag == null
                      ? const Duration(milliseconds: 200)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  left: at.dx,
                  top: at.dy,
                  child: GestureDetector(
                    onTap: _toggle,
                    onPanStart: (_) => setState(() => _drag = rest),
                    onPanUpdate: (d) => setState(
                      () => _drag = Offset(
                        (_drag!.dx + d.delta.dx).clamp(0, w - s),
                        (_drag!.dy + d.delta.dy).clamp(minY, maxY),
                      ),
                    ),
                    onPanEnd: (_) => setState(() {
                      _right = _drag!.dx + s / 2 > w / 2;
                      _y = _drag!.dy / h;
                      _drag = null;
                    }),
                    child: _Bubble(count: patient.events.length),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: 'Horas da ocorrência, $count registadas',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: EventsBubble.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Palette.navy,
              shape: const CircleBorder(
                side: BorderSide(color: Colors.white, width: 2),
              ),
              elevation: 6,
              child: const Center(
                child: Icon(Icons.schedule, color: Colors.white, size: 28),
              ),
            ),
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Palette.amber,
                    shape: BoxShape.circle,
                  ),
                  // Above the navigator there is no Material to style text.
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: Palette.black,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The occurrence times in a speech bubble that grows out of the bubble at
/// [anchor], above it or below it, wherever there is more room.
Future<void> showEventsPanel(BuildContext context, Rect anchor) =>
    showGeneralDialog(
      context: context,
      routeSettings: const RouteSettings(name: _panelRoute),
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, _) => _SpeechBubbleLayout(anchor: anchor),
      // The layout animates itself, from the bubble outwards.
      transitionBuilder: (context, animation, _, child) => child,
    );

class _SpeechBubbleLayout extends StatelessWidget {
  const _SpeechBubbleLayout({required this.anchor});

  final Rect anchor;

  static const _maxWidth = 380.0;
  static const _margin = 12.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)!.animation!;
    final pad = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final width = math.min(_maxWidth, size.width - 2 * _margin);
        final left = (anchor.center.dx - width / 2).clamp(
          _margin,
          size.width - _margin - width,
        );
        final spaceAbove = anchor.top - pad.top - _gap - _margin;
        final spaceBelow =
            size.height - pad.bottom - anchor.bottom - _gap - _margin;
        final above = spaceAbove >= spaceBelow;
        // Tail position along the bubble's edge, kept off the corners.
        final tailX = (anchor.center.dx - left).clamp(
          _SpeechBubbleBorder.radius + _SpeechBubbleBorder.tail,
          width - _SpeechBubbleBorder.radius - _SpeechBubbleBorder.tail,
        );
        final grow = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        final panel = FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: grow,
            // Grows out of the tail, i.e. out of the bubble.
            alignment: Alignment(tailX / width * 2 - 1, above ? 1 : -1),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: above ? spaceAbove : spaceBelow,
              ),
              child: EventsPanel(tailX: tailX, tailBelow: above),
            ),
          ),
        );
        return Stack(
          children: [
            Positioned(
              left: left,
              width: width,
              top: above ? null : anchor.bottom + _gap,
              bottom: above ? size.height - anchor.top + _gap : null,
              child: panel,
            ),
          ],
        );
      },
    );
  }
}

/// A rounded box with a small triangular tail on its top or bottom edge,
/// pointing at the bubble it came from.
class _SpeechBubbleBorder extends ShapeBorder {
  const _SpeechBubbleBorder({required this.tailX, required this.tailBelow});

  static const radius = 24.0;
  static const tail = 12.0;

  final double tailX;
  final bool tailBelow;

  @override
  EdgeInsetsGeometry get dimensions => tailBelow
      ? const EdgeInsets.only(bottom: tail)
      : const EdgeInsets.only(top: tail);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final body = tailBelow
        ? Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - tail)
        : Rect.fromLTRB(rect.left, rect.top + tail, rect.right, rect.bottom);
    final x = rect.left + tailX;
    final edge = tailBelow ? body.bottom : body.top;
    final tip = tailBelow ? rect.bottom : rect.top;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(radius)))
      ..moveTo(x - tail, edge)
      ..lineTo(x, tip)
      ..lineTo(x + tail, edge)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

/// The occurrence times: tap to stamp now, tap a stamped time to change
/// it, ✕ to clear it.
class EventsPanel extends StatelessWidget {
  const EventsPanel({super.key, this.tailX = 40, this.tailBelow = true});

  /// Where the speech bubble's tail sits, and on which edge.
  final double tailX;
  final bool tailBelow;

  Future<void> _edit(
    BuildContext context,
    PatientStore patient,
    PatientEvent event,
    DateTime current,
  ) async {
    final at = await pickClockTime(
      context,
      initial: current,
      title: event.label,
    );
    if (at != null) patient.setEvent(event, at);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final patient = AppScope.of(context).patient;
    final tail = _SpeechBubbleBorder.tail;
    return Material(
      color: scheme.pageBackground,
      elevation: 8,
      shape: _SpeechBubbleBorder(tailX: tailX, tailBelow: tailBelow),
      clipBehavior: Clip.antiAlias,
      child: ListenableBuilder(
        listenable: patient,
        builder: (context, _) {
          final events = patient.events;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              14,
              tailBelow ? 6 : 6 + tail,
              14,
              tailBelow ? 14 + tail : 14,
            ),
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
                const SizedBox(height: 10),
                for (final (i, event) in PatientEvent.values.indexed)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                    child: _EventTile(
                      event: event,
                      at: events[event],
                      onStamp: () => patient.setEvent(event, DateTime.now()),
                      onEdit: () =>
                          _edit(context, patient, event, events[event]!),
                      onClear: () => patient.setEvent(event, null),
                    ),
                  ),
              ],
            ),
          );
        },
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
          Expanded(child: TileLabel(event.label, color: fg)),
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
