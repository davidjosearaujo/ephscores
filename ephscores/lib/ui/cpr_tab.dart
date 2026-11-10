import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../cpr/cpr.dart';
import '../patient/patient.dart';
import '../platform/android.dart';
import '../theme.dart';
import 'cpr_page.dart';
import 'events_overlay.dart';
import 'widgets.dart';

/// A red tab on the left edge of every page, with or without a patient
/// open. Pull it out: past halfway it lets go of you and opens the CPR page,
/// starting the resuscitation (and the metronome) if there is none yet;
/// released before halfway it goes back. A tap only nudges it, to show what
/// it does, so it can't start anything by accident. It steps aside while
/// typing, while a dialog is open and on the CPR page itself.
class CprTab extends StatefulWidget {
  const CprTab({super.key, required this.navigatorKey, required this.popups});

  final GlobalKey<NavigatorState> navigatorKey;
  final PopupTracker popups;

  static const tabWidth = 30.0;
  static const height = 88.0;

  /// How far it must be pulled (0 to 1) to open the CPR page.
  static const commitAt = 0.5;

  @override
  State<CprTab> createState() => _CprTabState();
}

class _CprTabState extends State<CprTab> with SingleTickerProviderStateMixin {
  /// Where the tab sits down the screen (0 to 1).
  static const _y = 0.3;
  static const _margin = 8.0;

  /// 0 when only the tab shows, 1 when fully pulled out.
  late final AnimationController _pull = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late final PatientStore _patient = AppScope.of(context).patient;

  late final Listenable _shown = Listenable.merge([
    _patient,
    widget.popups.open,
    widget.popups.panelOpen,
    widget.popups.cprOpen,
  ]);

  /// Where the system back swipe is kept off, in physical pixels.
  Rect? _excluded;

  /// Past the point where letting go opens the page.
  bool _armed = false;

  @override
  void dispose() {
    _pull.dispose();
    excludeFromBackGesture(null);
    super.dispose();
  }

  /// The system's back swipe starts at the screen edge, where the tab is:
  /// without this, dragging the tab would leave the page. [top] is where the
  /// tab is within [context], or null when it is hidden.
  void _keepOffBackGesture(BuildContext context, double? top) {
    Rect? area;
    final box = context.findRenderObject();
    if (mounted && top != null && box is RenderBox && box.attached) {
      final scale = MediaQuery.devicePixelRatioOf(this.context);
      final at = box.localToGlobal(Offset(0, top));
      area = Rect.fromLTWH(
        at.dx * scale,
        at.dy * scale,
        (CprTab.tabWidth + 8) * scale,
        CprTab.height * scale,
      );
    }
    if (area == _excluded) return;
    _excluded = area;
    excludeFromBackGesture(area);
  }

  void _dragged(double by) {
    _pull.value += by;
    final armed = _pull.value > CprTab.commitAt;
    if (armed != _armed) {
      _armed = armed;
      HapticFeedback.selectionClick();
    }
  }

  /// Opens the CPR page if pulled far enough, else goes back.
  Future<void> _released() async {
    final commit = _pull.value > CprTab.commitAt;
    _armed = false;
    if (!commit) return _pull.animateTo(0, curve: Curves.easeOutCubic);
    HapticFeedback.mediumImpact();
    await _pull.animateTo(1, duration: const Duration(milliseconds: 100));
    await _go();
  }

  /// Goes to the CPR page, starting the resuscitation if need be.
  Future<void> _go() async {
    final navigator = widget.navigatorKey.currentState;
    if (navigator != null) await beginCpr(navigator);
    if (mounted) _pull.value = 0;
  }

  /// A tap shows what the tab does, then it goes back.
  Future<void> _nudge() async {
    await _pull.animateTo(0.35, curve: Curves.easeOut);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted && !_pull.isDismissed) {
      await _pull.animateTo(0, curve: Curves.easeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final popups = widget.popups;
    return ListenableBuilder(
      listenable: _shown,
      builder: (context, _) {
        if (popups.open.value > 0 ||
            popups.panelOpen.value ||
            popups.cprOpen.value ||
            MediaQuery.viewInsetsOf(context).bottom > 0) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _keepOffBackGesture(context, null),
          );
          return const SizedBox.shrink();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final pad = MediaQuery.paddingOf(context);
            final h = constraints.maxHeight;
            final top = (_y * h)
                .clamp(
                  pad.top + _margin,
                  math.max(pad.top + _margin, h - pad.bottom - CprTab.height),
                )
                .toDouble();
            final panelWidth = math.min(
              270.0,
              constraints.maxWidth - CprTab.tabWidth - 24,
            );
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _keepOffBackGesture(context, top),
            );
            return AnimatedBuilder(
              animation: _pull,
              builder: (context, _) => Stack(
                children: [
                  Positioned(
                    top: top,
                    left: -panelWidth * (1 - _pull.value),
                    child: GestureDetector(
                      onTap: _nudge,
                      onHorizontalDragUpdate: (d) =>
                          _dragged(d.delta.dx / panelWidth),
                      onHorizontalDragEnd: (_) => _released(),
                      onHorizontalDragCancel: _released,
                      child: Row(
                        children: [
                          _Pulled(
                            width: panelWidth,
                            patient: _patient,
                            armed: _pull.value > CprTab.commitAt,
                          ),
                          _Tab(onActivate: _go),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// The part that stays in view: "PCR" in white on red.
class _Tab extends StatelessWidget {
  const _Tab({required this.onActivate});

  /// What a screen reader's action does, since it can't drag.
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: 'PCR, paragem cardiorrespiratória',
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Começar SBV/DAE'): onActivate,
      },
      excludeSemantics: true,
      child: Material(
        color: Palette.red,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
        ),
        child: const SizedBox(
          width: CprTab.tabWidth,
          height: CprTab.height,
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'PCR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the tab pulls out: what letting go will do, on red that darkens once
/// it is pulled far enough.
class _Pulled extends StatelessWidget {
  const _Pulled({
    required this.width,
    required this.patient,
    required this.armed,
  });

  final double width;
  final PatientStore patient;
  final bool armed;

  @override
  Widget build(BuildContext context) {
    final cpr = patient.isActive || patient.isFinished ? patient.cpr : null;
    final label = switch (cpr) {
      null => 'Começar SBV/DAE',
      Cpr(isOngoing: true) => 'RCP em curso · ${cpr.counts}',
      _ => 'Ver a RCP · ${cpr.counts}',
    };
    return Material(
      color: armed ? const Color(0xFFB3261E) : Palette.red,
      elevation: 6,
      child: SizedBox(
        width: width,
        height: CprTab.height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FitText(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
