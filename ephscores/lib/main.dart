import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'burn/burn.dart';
import 'scores/score_store.dart';
import 'start/start.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Roboto',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final prefs = await SharedPreferences.getInstance();
  await migrateLegacyPrefs(prefs);
  runApp(
    EPHScoresApp(
      scores: ScoreStore(prefs),
      start: StartStore(prefs),
      burn: BurnStore(prefs),
    ),
  );
}

/// Version 1 stored dozens of loose keys ("s4.3", "head_front", ...). Carry
/// over the START counters and drop everything else.
Future<void> migrateLegacyPrefs(SharedPreferences prefs) async {
  final legacy = prefs.getKeys().where((k) => !k.endsWith('.v2')).toList();
  if (legacy.isEmpty) return;
  final start = StartStore(prefs);
  if (start.total == 0) {
    for (final (i, c) in StartCategory.values.indexed) {
      final n = prefs.getInt('p${i + 1}') ?? 0;
      for (var j = 0; j < n; j++) {
        start.add(c);
      }
    }
  }
  for (final k in legacy) {
    await prefs.remove(k);
  }
}
