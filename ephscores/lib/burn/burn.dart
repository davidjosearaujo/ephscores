import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BurnPatient { adult, child }

enum BodyView { front, back }

enum BurnDegree {
  none('Sem lesão'),
  first('1.º grau'),
  second('2.º grau'),
  third('3.º grau');

  const BurnDegree(this.label);

  final String label;

  /// First-degree burns are excluded from the burned surface area.
  bool get countsForTbsa => index >= BurnDegree.second.index;
}

/// Anatomical shape, shared by the adult and child diagrams.
enum BodyPart {
  head,
  upperTorso,
  lowerTorso,
  torso,
  genitals,
  rightArm,
  leftArm,
  rightLeg,
  leftLeg,
}

class BodyRegion {
  const BodyRegion(this.view, this.part, this.label, this.percent);

  final BodyView view;
  final BodyPart part;
  final String label;
  final double percent;

  String get id => '${view.name}.${part.name}';
}

/// Rule of nines (adult) and its paediatric adaptation.
const Map<BurnPatient, List<BodyRegion>> bodyRegions = {
  BurnPatient.adult: [
    BodyRegion(BodyView.front, BodyPart.head, 'Cabeça', 4.5),
    BodyRegion(BodyView.front, BodyPart.upperTorso, 'Tórax', 9),
    BodyRegion(BodyView.front, BodyPart.lowerTorso, 'Abdómen', 9),
    BodyRegion(BodyView.front, BodyPart.genitals, 'Genitais', 1),
    BodyRegion(
      BodyView.front,
      BodyPart.rightArm,
      'Membro superior direito',
      4.5,
    ),
    BodyRegion(
      BodyView.front,
      BodyPart.leftArm,
      'Membro superior esquerdo',
      4.5,
    ),
    BodyRegion(BodyView.front, BodyPart.rightLeg, 'Membro inferior direito', 9),
    BodyRegion(BodyView.front, BodyPart.leftLeg, 'Membro inferior esquerdo', 9),
    BodyRegion(BodyView.back, BodyPart.head, 'Cabeça', 4.5),
    BodyRegion(BodyView.back, BodyPart.upperTorso, 'Dorso superior', 9),
    BodyRegion(
      BodyView.back,
      BodyPart.lowerTorso,
      'Dorso inferior e nádegas',
      9,
    ),
    BodyRegion(
      BodyView.back,
      BodyPart.rightArm,
      'Membro superior direito',
      4.5,
    ),
    BodyRegion(
      BodyView.back,
      BodyPart.leftArm,
      'Membro superior esquerdo',
      4.5,
    ),
    BodyRegion(BodyView.back, BodyPart.rightLeg, 'Membro inferior direito', 9),
    BodyRegion(BodyView.back, BodyPart.leftLeg, 'Membro inferior esquerdo', 9),
  ],
  BurnPatient.child: [
    BodyRegion(BodyView.front, BodyPart.head, 'Cabeça', 9),
    BodyRegion(BodyView.front, BodyPart.torso, 'Tronco', 18),
    BodyRegion(
      BodyView.front,
      BodyPart.rightArm,
      'Membro superior direito',
      4.5,
    ),
    BodyRegion(
      BodyView.front,
      BodyPart.leftArm,
      'Membro superior esquerdo',
      4.5,
    ),
    BodyRegion(BodyView.front, BodyPart.rightLeg, 'Membro inferior direito', 7),
    BodyRegion(BodyView.front, BodyPart.leftLeg, 'Membro inferior esquerdo', 7),
    BodyRegion(BodyView.back, BodyPart.head, 'Cabeça', 9),
    BodyRegion(BodyView.back, BodyPart.torso, 'Tronco', 18),
    BodyRegion(
      BodyView.back,
      BodyPart.rightArm,
      'Membro superior direito',
      4.5,
    ),
    BodyRegion(
      BodyView.back,
      BodyPart.leftArm,
      'Membro superior esquerdo',
      4.5,
    ),
    BodyRegion(BodyView.back, BodyPart.rightLeg, 'Membro inferior direito', 7),
    BodyRegion(BodyView.back, BodyPart.leftLeg, 'Membro inferior esquerdo', 7),
  ],
};

class BurnStore extends ChangeNotifier {
  BurnStore(this._prefs) {
    _load();
  }

  static const _key = 'burn.v2';

  final SharedPreferences _prefs;
  BurnPatient _patient = BurnPatient.adult;
  final Map<BurnPatient, Map<String, BurnDegree>> _degrees = {
    for (final p in BurnPatient.values) p: {},
  };

  BurnPatient get patient => _patient;

  set patient(BurnPatient value) {
    _patient = value;
    _changed();
  }

  List<BodyRegion> get regions => bodyRegions[_patient]!;

  BurnDegree degreeOf(BodyRegion region) =>
      _degrees[_patient]![region.id] ?? BurnDegree.none;

  /// Paints [region] with [degree], or clears it if it already has that degree.
  void paint(BodyRegion region, BurnDegree degree) {
    final map = _degrees[_patient]!;
    if (degree == BurnDegree.none || map[region.id] == degree) {
      map.remove(region.id);
    } else {
      map[region.id] = degree;
    }
    _changed();
  }

  double percentWhere(bool Function(BurnDegree d) test) => [
    for (final r in regions)
      if (test(degreeOf(r))) r.percent,
  ].fold(0.0, (a, b) => a + b);

  /// Total burned surface area (2nd and 3rd degree only).
  double get tbsa => percentWhere((d) => d.countsForTbsa);

  bool get isEmpty => _degrees.values.every((m) => m.isEmpty);

  /// Clears the current patient type only.
  void clear() {
    _degrees[_patient]!.clear();
    _changed();
  }

  void clearAll() {
    for (final m in _degrees.values) {
      m.clear();
    }
    _changed();
  }

  void _changed() {
    notifyListeners();
    _prefs.setString(
      _key,
      jsonEncode({
        'patient': _patient.name,
        for (final MapEntry(key: p, value: m) in _degrees.entries)
          p.name: {for (final e in m.entries) e.key: e.value.name},
      }),
    );
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _patient = BurnPatient.values.byName(data['patient'] as String);
      for (final p in BurnPatient.values) {
        final ids = {for (final r in bodyRegions[p]!) r.id};
        for (final MapEntry(:key, :value)
            in ((data[p.name] ?? {}) as Map).entries) {
          if (ids.contains(key)) {
            _degrees[p]![key as String] = BurnDegree.values.byName(
              value as String,
            );
          }
        }
      }
    } on Object catch (e) {
      debugPrint('Discarding saved burns: $e');
    }
  }
}
