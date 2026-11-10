import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../patient/patient.dart';
import '../theme.dart';
import 'cpr_page.dart' show cprRoute;
import 'widgets.dart';

/// Name of the route of the occurrence-times panel.
const _panelRoute = 'events';

/// Counts the dialogs and sheets open on the navigator, so the floating
/// bubble and tab can step aside while one is shown, and tracks the times
/// panel, which keeps the bubble in view, and the CPR page.
class PopupTracker extends NavigatorObserver {
  /// Dialogs other than the times panel.
  final open = ValueNotifier<int>(0);

  /// The times panel is showing.
  final panelOpen = ValueNotifier<bool>(false);

  /// The CPR page is showing.
  final cprOpen = ValueNotifier<bool>(false);

  void _change(Route<dynamic>? route, int by) {
    if (route?.settings.name == cprRoute) {
      cprOpen.value = by > 0;
      return;
    }
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
/// typing or while a dialog is open. Its panel opens below it, or above
/// when there's no room below; if neither fits, the bubble moves just far
/// enough while the panel is open.
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

  /// Where the bubble moved to (its top) so its open panel fits; null when
  /// it didn't need to move.
  double? _openTop;

  final _stackKey = GlobalKey();

  /// The resting place, from the last layout.
  Offset _rest = Offset.zero;

  late final PatientStore _patient = AppScope.of(context).patient;

  /// What shows or hides the bubble; merged once, not on every build.
  late final Listenable _shown = Listenable.merge([
    _patient,
    widget.popups.open,
    widget.popups.panelOpen,
  ]);

  void _toggle() {
    final navigator = widget.navigatorKey.currentState;
    if (widget.popups.panelOpen.value) {
      navigator?.pop();
      return;
    }
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = navigator?.overlay?.context.findRenderObject();
    if (navigator == null || stack == null || overlay == null) return;
    // The bubble, in the coordinates the panel is laid out in.
    final origin = stack.localToGlobal(Offset.zero, ancestor: overlay);
    final anchor = (_rest + origin) & const Size.square(EventsBubble.size);
    setState(() => _openTop = null);
    showEventsPanel(
      navigator.context,
      anchor,
      onMoveBubble: (top) => setState(() => _openTop = top - origin.dy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = _patient;
    final popups = widget.popups;
    return ListenableBuilder(
      listenable: _shown,
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
            _rest = rest;
            final openTop = popups.panelOpen.value ? _openTop : null;
            final at = _drag ?? (openTop == null ? rest : Offset(x, openTop));
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
/// [anchor]. It opens below the bubble when it fits there, otherwise above;
/// when it fits on neither side, [onMoveBubble] is asked to move the bubble
/// (to a new top, in the same coordinates as [anchor]) just far enough.
Future<void> showEventsPanel(
  BuildContext context,
  Rect anchor, {
  required ValueChanged<double> onMoveBubble,
}) => showGeneralDialog(
  context: context,
  routeSettings: const RouteSettings(name: _panelRoute),
  barrierDismissible: true,
  barrierLabel: 'Fechar',
  barrierColor: Colors.black38,
  transitionDuration: const Duration(milliseconds: 200),
  pageBuilder: (context, _, _) =>
      _SpeechBubbleLayout(anchor: anchor, onMoveBubble: onMoveBubble),
  // The layout animates itself, from the bubble outwards.
  transitionBuilder: (context, animation, _, child) => child,
);

/// Where the panel goes: next to the bubble, whose top may have moved.
typedef PanelPlacement = ({double bubbleTop, bool above});

/// Chooses where a panel of [height] goes next to a bubble at [anchor],
/// within [top] and [bottom]: below if it fits, else above, else the
/// smallest move of the bubble that makes it fit on one side.
@visibleForTesting
PanelPlacement placePanel({
  required Rect anchor,
  required double height,
  required double top,
  required double bottom,
  double gap = 4,
}) {
  final s = anchor.height;
  if (anchor.bottom + gap + height <= bottom) {
    return (bubbleTop: anchor.top, above: false);
  }
  if (anchor.top - gap - height >= top) {
    return (bubbleTop: anchor.top, above: true);
  }
  // Up until it fits below, or down until it fits above.
  final up = bottom - height - gap - s;
  final down = top + height + gap;
  final canUp = up >= top, canDown = down + s <= bottom;
  if (canUp && (!canDown || anchor.top - up <= down - anchor.top)) {
    return (bubbleTop: up, above: false);
  }
  if (canDown) return (bubbleTop: down, above: true);
  // Taller than the screen: bubble at the bottom, panel scrolls above it.
  return (bubbleTop: bottom - s, above: true);
}

class _SpeechBubbleLayout extends StatefulWidget {
  const _SpeechBubbleLayout({required this.anchor, required this.onMoveBubble});

  final Rect anchor;
  final ValueChanged<double> onMoveBubble;

  @override
  State<_SpeechBubbleLayout> createState() => _SpeechBubbleLayoutState();
}

class _SpeechBubbleLayoutState extends State<_SpeechBubbleLayout> {
  static const _maxWidth = 380.0;
  static const _margin = 12.0;
  static const _gap = 4.0;

  /// Measures the panel's natural height on the first frame.
  final _measure = GlobalKey();
  PanelPlacement? _placement;

  void _place(Size size, EdgeInsets pad) {
    final box = _measure.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;
    final placement = placePanel(
      anchor: widget.anchor,
      height: box.size.height,
      top: pad.top + _margin,
      bottom: size.height - pad.bottom - _margin,
      gap: _gap,
    );
    if (placement.bubbleTop != widget.anchor.top) {
      widget.onMoveBubble(placement.bubbleTop);
    }
    setState(() => _placement = placement);
  }

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)!.animation!;
    final pad = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final width = math.min(_maxWidth, size.width - 2 * _margin);
        final anchor = widget.anchor;
        final left = (anchor.center.dx - width / 2).clamp(
          _margin,
          size.width - _margin - width,
        );
        // Tail position along the panel's edge, kept off the corners.
        final tailX = (anchor.center.dx - left).clamp(
          _SpeechBubbleBorder.radius + _SpeechBubbleBorder.tail,
          width - _SpeechBubbleBorder.radius - _SpeechBubbleBorder.tail,
        );
        final placement = _placement;
        if (placement == null) {
          // First frame: lay the panel out unseen to learn its height.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _place(size, pad),
          );
          return Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: width,
                child: Offstage(
                  child: EventsPanel(key: _measure, tailX: tailX),
                ),
              ),
            ],
          );
        }
        final above = placement.above;
        final bubble = Rect.fromLTWH(
          anchor.left,
          placement.bubbleTop,
          anchor.width,
          anchor.height,
        );
        final grow = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return Stack(
          children: [
            Positioned(
              left: left,
              width: width,
              top: above ? null : bubble.bottom + _gap,
              bottom: above ? size.height - bubble.top + _gap : null,
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: grow,
                  // Grows out of the tail, i.e. out of the bubble.
                  alignment: Alignment(tailX / width * 2 - 1, above ? 1 : -1),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: above
                          ? bubble.top - pad.top - _gap - _margin
                          : size.height -
                                pad.bottom -
                                bubble.bottom -
                                _gap -
                                _margin,
                    ),
                    child: EventsPanel(tailX: tailX, tailBelow: above),
                  ),
                ),
              ),
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
                    child: TimeStampTile(
                      label: event.label,
                      at: events[event],
                      onChanged: (at) => patient.setEvent(event, at),
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
