/// The injury map: what was found where on the body, by type of injury,
/// on the same body regions as the burn map.
library;

import 'package:flutter/foundation.dart';

import '../burn/burn.dart';

/// How worrying an injury is, for colouring the map.
enum InjuryLevel { major, serious, minor }

enum InjuryType {
  bleeding('Hemorragia ativa', InjuryLevel.major),
  penetrating('Ferida penetrante', InjuryLevel.major),
  amputation('Amputação', InjuryLevel.major),
  fracture('Fratura suspeita', InjuryLevel.serious),
  deformity('Deformidade ou luxação', InjuryLevel.serious),
  wound('Ferida', InjuryLevel.minor),
  contusion('Contusão ou hematoma', InjuryLevel.minor),
  pain('Dor', InjuryLevel.minor);

  const InjuryType(this.label, this.level);

  final String label;
  final InjuryLevel level;
}

/// Regions where a penetrating wound meets the Via Verde Trauma criterion
/// (head, neck, trunk, perineum); limbs would need to know how far up.
const _trunkParts = {
  BodyPart.head,
  BodyPart.upperTorso,
  BodyPart.lowerTorso,
  BodyPart.torso,
  BodyPart.genitals,
};

/// Injuries by region, for an adult and for a child. Immutable.
@immutable
class InjuryMap {
  const InjuryMap({
    this.patient = BurnPatient.adult,
    this.byPatient = const {},
  });

  factory InjuryMap.fromJson(Map<String, dynamic> json) {
    final byPatient = <BurnPatient, Map<String, Set<InjuryType>>>{};
    for (final p in BurnPatient.values) {
      final ids = {for (final r in bodyRegions[p]!) r.id};
      final regions = <String, Set<InjuryType>>{};
      for (final MapEntry(:key, :value)
          in ((json[p.name] as Map?) ?? const {}).entries) {
        final types = {
          for (final name in value as List)
            ?InjuryType.values.asNameMap()[name],
        };
        if (ids.contains(key) && types.isNotEmpty) {
          regions[key as String] = types;
        }
      }
      if (regions.isNotEmpty) byPatient[p] = regions;
    }
    return InjuryMap(
      patient:
          BurnPatient.values.asNameMap()[json['patient']] ?? BurnPatient.adult,
      byPatient: byPatient,
    );
  }

  /// The body shown: adult or child.
  final BurnPatient patient;
  final Map<BurnPatient, Map<String, Set<InjuryType>>> byPatient;

  List<BodyRegion> get regions => bodyRegions[patient]!;

  Set<InjuryType> typesOf(BodyRegion r) =>
      byPatient[patient]?[r.id] ?? const {};

  /// Regions of the shown body with something recorded, in body order.
  List<BodyRegion> get affected => [
    for (final r in regions)
      if (typesOf(r).isNotEmpty) r,
  ];

  bool get isEmpty => byPatient.isEmpty;

  /// The worst level recorded in [r], or null when there is none.
  InjuryLevel? levelOf(BodyRegion r) => typesOf(r).isEmpty
      ? null
      : typesOf(r)
            .map((t) => t.level)
            .reduce((a, b) => a.index < b.index ? a : b);

  /// Something other than pain is recorded: an injury, so a trauma.
  bool get traumaSigns =>
      regions.any((r) => typesOf(r).any((t) => t != InjuryType.pain));

  /// A penetrating wound of the head or trunk: meets a Via Verde Trauma
  /// criterion.
  bool get penetratingTrunk => regions.any(
    (r) =>
        _trunkParts.contains(r.part) &&
        typesOf(r).contains(InjuryType.penetrating),
  );

  InjuryMap withPatient(BurnPatient p) =>
      InjuryMap(patient: p, byPatient: byPatient);

  /// Ticks or unticks [type] in [r].
  InjuryMap toggle(BodyRegion r, InjuryType type) {
    final now = typesOf(r);
    final next = now.contains(type) ? ({...now}..remove(type)) : {...now, type};
    return _with(r, next);
  }

  InjuryMap clearRegion(BodyRegion r) => _with(r, const {});

  InjuryMap _with(BodyRegion r, Set<InjuryType> types) {
    final regions = {
      for (final MapEntry(:key, :value)
          in (byPatient[patient] ?? const <String, Set<InjuryType>>{}).entries)
        if (key != r.id) key: value,
      if (types.isNotEmpty) r.id: types,
    };
    return InjuryMap(
      patient: patient,
      byPatient: {
        for (final MapEntry(:key, :value) in byPatient.entries)
          if (key != patient) key: value,
        if (regions.isNotEmpty) patient: regions,
      },
    );
  }

  /// One line per affected region: "Membro superior direito (anterior):
  /// fratura suspeita, dor".
  List<String> lines() => [
    for (final r in affected)
      '${r.label} (${r.view == BodyView.front ? 'anterior' : 'posterior'}): '
          '${[for (final t in InjuryType.values)
            if (typesOf(r).contains(t)) t.label.toLowerCase()].join(', ')}',
  ];

  Map<String, Object> toJson() => {
    'patient': patient.name,
    for (final MapEntry(:key, :value) in byPatient.entries)
      key.name: {
        for (final id in value.keys.toList()..sort())
          id: [
            for (final t
                in value[id]!.toList()..sort((a, b) => a.index - b.index))
              t.name,
          ],
      },
  };
}
