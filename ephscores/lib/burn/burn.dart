import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../persistence.dart';

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

/// Burn degrees painted on the body map at one moment, for both patient
/// types. The store keeps the live sheet; evaluations keep a [copy].
class BurnSheet {
  BurnSheet()
    : this._(BurnPatient.adult, {for (final p in BurnPatient.values) p: {}});

  BurnSheet._(this._patient, this._degrees);

  /// Parses [toJson] output, dropping unknown regions.
  factory BurnSheet.fromJson(Object? json) {
    final data = json as Map<String, dynamic>;
    final sheet = BurnSheet()
      .._patient = BurnPatient.values.byName(data['patient'] as String);
    for (final p in BurnPatient.values) {
      final ids = {for (final r in bodyRegions[p]!) r.id};
      for (final MapEntry(:key, :value)
          in ((data[p.name] ?? {}) as Map).entries) {
        if (ids.contains(key)) {
          sheet._degrees[p]![key as String] = BurnDegree.values.byName(
            value as String,
          );
        }
      }
    }
    return sheet;
  }

  BurnPatient _patient;
  final Map<BurnPatient, Map<String, BurnDegree>> _degrees;

  BurnPatient get patient => _patient;

  List<BodyRegion> get regions => bodyRegions[_patient]!;

  BurnDegree degreeOf(BodyRegion region) =>
      _degrees[_patient]![region.id] ?? BurnDegree.none;

  double percentWhere(bool Function(BurnDegree d) test) => [
    for (final r in regions)
      if (test(degreeOf(r))) r.percent,
  ].fold(0.0, (a, b) => a + b);

  /// Total burned surface area (2nd and 3rd degree only).
  double get tbsa => percentWhere((d) => d.countsForTbsa);

  bool get isEmpty => _degrees.values.every((m) => m.isEmpty);

  /// Whether the selected patient type has any region painted.
  bool get hasBurns => _degrees[_patient]!.isNotEmpty;

  BurnSheet copy() => BurnSheet._(_patient, {
    for (final MapEntry(key: p, value: m) in _degrees.entries) p: {...m},
  });

  /// Sorted, so equal sheets always encode to the same string.
  Map<String, Object> toJson() => {
    'patient': _patient.name,
    for (final MapEntry(key: p, value: m) in _degrees.entries)
      p.name: {for (final id in m.keys.toList()..sort()) id: m[id]!.name},
  };

  bool sameAs(BurnSheet other) =>
      jsonEncode(toJson()) == jsonEncode(other.toJson());
}

class BurnStore extends PersistedStore {
  BurnStore(SharedPreferences prefs) : super(prefs, 'burn.v2') {
    load();
  }

  BurnSheet _sheet = BurnSheet();

  /// The live burn map. Take a [BurnSheet.copy] to keep a snapshot.
  BurnSheet get sheet => _sheet;

  BurnPatient get patient => _sheet.patient;

  set patient(BurnPatient value) {
    _sheet._patient = value;
    changed();
  }

  List<BodyRegion> get regions => _sheet.regions;

  BurnDegree degreeOf(BodyRegion region) => _sheet.degreeOf(region);

  /// Paints [region] with [degree], or clears it if it already has that degree.
  void paint(BodyRegion region, BurnDegree degree) {
    final map = _sheet._degrees[_sheet.patient]!;
    if (degree == BurnDegree.none || map[region.id] == degree) {
      map.remove(region.id);
    } else {
      map[region.id] = degree;
    }
    changed();
  }

  double percentWhere(bool Function(BurnDegree d) test) =>
      _sheet.percentWhere(test);

  double get tbsa => _sheet.tbsa;

  bool get isEmpty => _sheet.isEmpty;

  /// Clears the current patient type only.
  void clear() {
    _sheet._degrees[_sheet.patient]!.clear();
    changed();
  }

  void clearAll() {
    for (final m in _sheet._degrees.values) {
      m.clear();
    }
    changed();
  }

  @override
  Object toJson() => _sheet.toJson();

  @override
  void restore(Object? json) => _sheet = BurnSheet.fromJson(json);
}
