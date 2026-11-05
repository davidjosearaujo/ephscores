import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Self-reported pain on six faces (0, 2, 4, 6, 8, 10), for children from
/// 3 years old (DGS guidance 014/2010). The drawings are EPHScores' own,
/// in the app's traffic-light colours.
const painFaceLevels = [
  (0, 'Sem dor'),
  (2, 'Pouca dor'),
  (4, 'Alguma dor'),
  (6, 'Bastante dor'),
  (8, 'Muita dor'),
  (10, 'Dor máxima'),
];

Color painFaceColor(int value) {
  const stops = [Palette.green, Palette.amber, Palette.orange, Palette.red];
  final t = value / 10 * (stops.length - 1);
  final i = t.floor().clamp(0, stops.length - 2);
  return Color.lerp(stops[i], stops[i + 1], t - i)!;
}

/// A row of the six faces. [selected] is the chosen value, if any.
class PainFaces extends StatelessWidget {
  const PainFaces({super.key, required this.selected, required this.onTap});

  final int? selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = painFaceLevels
        .where((l) => l.$1 == selected)
        .map((l) => l.$2)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (value, name) in painFaceLevels)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selected == value,
                  label: '$value, $name',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onTap(value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 3,
                                color: selected == value
                                    ? scheme.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: CustomPaint(
                                painter: PainFacePainter(value),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$value',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: selected == value
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Text(
          label ?? 'Pedir à criança que aponte a face que mostra a sua dor.',
          textAlign: TextAlign.center,
          style: label == null
              ? theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                )
              : theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
        ),
      ],
    );
  }
}

/// One face: a filled disc whose mouth turns from a smile (0) to a frown
/// (10), with brows that tighten and eyes that squeeze shut from 8.
class PainFacePainter extends CustomPainter {
  const PainFacePainter(this.value);

  final int value;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final t = value / 10;
    final fill = painFaceColor(value);
    canvas.drawCircle(c, r, Paint()..color = fill);
    final ink = Paint()
      ..color = value >= 4 && value <= 6 ? Palette.black : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.11
      ..strokeCap = StrokeCap.round;

    // Eyes: open dots, squeezed into chevrons from 8.
    final eyeY = c.dy - r * 0.18;
    for (final side in [-1.0, 1.0]) {
      final eye = Offset(c.dx + side * r * 0.36, eyeY);
      if (value >= 8) {
        final w = r * 0.14;
        canvas.drawPath(
          Path()
            ..moveTo(eye.dx - side * w, eye.dy - w)
            ..lineTo(eye.dx + side * w * 0.3, eye.dy)
            ..lineTo(eye.dx - side * w, eye.dy + w),
          ink,
        );
      } else {
        canvas.drawCircle(eye, r * 0.09, Paint()..color = ink.color);
      }
    }

    // Brows from 4, slanting more as the pain rises.
    if (value >= 4) {
      final tilt = (t - 0.3) * 0.5;
      for (final side in [-1.0, 1.0]) {
        final inner = Offset(
          c.dx + side * r * 0.16,
          eyeY - r * 0.22 - tilt * r,
        );
        final outer = Offset(c.dx + side * r * 0.52, eyeY - r * 0.30);
        canvas.drawLine(inner, outer, ink);
      }
    }

    // Mouth: a curve from smile to frown; open at 10.
    final mouthY = c.dy + r * 0.38;
    final half = r * 0.4;
    final bend = (0.5 - t) * r * 0.7;
    final mouth = Path()
      ..moveTo(c.dx - half, mouthY - bend * 0.3)
      ..quadraticBezierTo(
        c.dx,
        mouthY + bend,
        c.dx + half,
        mouthY - bend * 0.3,
      );
    if (value == 10) {
      mouth.quadraticBezierTo(
        c.dx,
        mouthY + bend * 0.2,
        c.dx - half,
        mouthY - bend * 0.3,
      );
      canvas.drawPath(mouth, Paint()..color = ink.color);
    } else {
      canvas.drawPath(mouth, ink);
    }

    // A faint highlight so the faces read as round on any background.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.82),
      math.pi * 1.15,
      math.pi * 0.35,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(PainFacePainter old) => old.value != value;
}
