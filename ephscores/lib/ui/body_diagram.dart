import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../burn/burn.dart';
import '../format.dart';

/// Diagram canvas size; shapes are laid out in these units and scaled to fit.
const _canvas = Size(200, 440);

/// Shape of each body part, as seen from the front (patient's right on the
/// viewer's left). The back view mirrors it horizontally.
Path _shape(BurnPatient patient, BodyPart part) {
  RRect r(double l, double t, double rr, double b, double radius) =>
      RRect.fromLTRBR(l, t, rr, b, Radius.circular(radius));
  final path = Path();
  switch ((patient, part)) {
    case (BurnPatient.adult, BodyPart.head):
      path.addOval(
        Rect.fromCenter(center: const Offset(100, 36), width: 50, height: 58),
      );
    case (BurnPatient.adult, BodyPart.upperTorso):
      path.addRRect(
        RRect.fromLTRBAndCorners(
          64,
          72,
          136,
          146,
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
        ),
      );
    case (BurnPatient.adult, BodyPart.lowerTorso):
      path.addRRect(
        RRect.fromLTRBAndCorners(
          66,
          150,
          134,
          214,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
        ),
      );
    case (BurnPatient.adult, BodyPart.genitals):
      path.addRRect(r(88, 208, 112, 232, 10));
    case (BurnPatient.adult, BodyPart.rightArm):
      path.addRRect(r(34, 78, 60, 262, 13));
    case (BurnPatient.adult, BodyPart.leftArm):
      path.addRRect(r(140, 78, 166, 262, 13));
    case (BurnPatient.adult, BodyPart.rightLeg):
      path.addRRect(r(66, 218, 98, 432, 15));
    case (BurnPatient.adult, BodyPart.leftLeg):
      path.addRRect(r(102, 218, 134, 432, 15));
    case (BurnPatient.child, BodyPart.head):
      path.addOval(
        Rect.fromCenter(center: const Offset(100, 50), width: 80, height: 88),
      );
    case (BurnPatient.child, BodyPart.torso):
      path.addRRect(
        RRect.fromLTRBAndCorners(
          62,
          100,
          138,
          262,
          topLeft: const Radius.circular(26),
          topRight: const Radius.circular(26),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
      );
    case (BurnPatient.child, BodyPart.rightArm):
      path.addRRect(r(30, 106, 58, 258, 14));
    case (BurnPatient.child, BodyPart.leftArm):
      path.addRRect(r(142, 106, 170, 258, 14));
    case (BurnPatient.child, BodyPart.rightLeg):
      path.addRRect(r(64, 266, 98, 420, 16));
    case (BurnPatient.child, BodyPart.leftLeg):
      path.addRRect(r(102, 266, 136, 420, 16));
    case _:
      break;
  }
  return path;
}

final _pathCache = <(BurnPatient, BodyView, BodyPart), Path>{};

/// Path of [region], cached since the geometry never changes. Callers must
/// not mutate it.
Path _regionPath(BurnPatient patient, BodyRegion region) =>
    _pathCache.putIfAbsent((
      patient,
      region.view,
      region.part,
    ), () => _buildRegionPath(patient, region));

Path _buildRegionPath(BurnPatient patient, BodyRegion region) {
  final path = _shape(patient, region.part);
  if (region.view == BodyView.front) return path;
  // Column-major 4x4: x' = width - x.
  final mirror = Float64List.fromList([
    -1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    _canvas.width,
    0,
    0,
    1,
  ]);
  return path.transform(mirror);
}

/// Tappable body outline for one view, coloured by burn degree.
class BodyDiagram extends StatelessWidget {
  const BodyDiagram({
    super.key,
    required this.patient,
    required this.view,
    required this.regions,
    required this.colorFor,
    required this.onTap,
  });

  final BurnPatient patient;
  final BodyView view;
  final List<BodyRegion> regions;
  final Color Function(BodyRegion) colorFor;
  final ValueChanged<BodyRegion> onTap;

  @override
  Widget build(BuildContext context) {
    final visible = regions.where((r) => r.view == view).toList();
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: _canvas.width / _canvas.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / _canvas.width;
          return GestureDetector(
            onTapUp: (details) {
              final p = details.localPosition / scale;
              // Topmost (last painted) region wins, so genitals beat the legs.
              for (final r in visible.reversed) {
                if (_regionPath(patient, r).contains(p)) {
                  onTap(r);
                  return;
                }
              }
            },
            child: CustomPaint(
              painter: _BodyPainter(
                patient: patient,
                regions: visible,
                colors: [for (final r in visible) colorFor(r)],
                gap: scheme.surface,
                scale: scale,
              ),
              child: Semantics(
                label:
                    'Diagrama corporal ${view == BodyView.front ? 'anterior' : 'posterior'}',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.patient,
    required this.regions,
    required this.colors,
    required this.gap,
    required this.scale,
  });

  final BurnPatient patient;
  final List<BodyRegion> regions;
  final List<Color> colors;
  final Color gap;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = gap;
    for (final (i, region) in regions.indexed) {
      final path = _regionPath(patient, region);
      canvas.drawPath(path, Paint()..color = colors[i]);
      canvas.drawPath(path, outline);

      final text = TextPainter(
        text: TextSpan(
          text: formatNumber(region.percent),
          style: TextStyle(
            fontSize: region.part == BodyPart.genitals ? 10 : 13,
            fontWeight: FontWeight.w700,
            color: colors[i].computeLuminance() > 0.45
                ? Colors.black87
                : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final c = path.getBounds().center;
      text.paint(canvas, c - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.patient != patient ||
      old.gap != gap ||
      old.scale != scale ||
      old.regions != regions ||
      !_listEquals(old.colors, colors);

  static bool _listEquals(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
