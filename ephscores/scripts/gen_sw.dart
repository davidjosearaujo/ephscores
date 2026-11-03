// Fills in web/sw.js after `flutter build web`: the precache list (app shell
// and assets) and a version derived from the content of every file.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

void main(List<String> args) {
  final root = Directory(args.isEmpty ? 'build/web' : args.first);
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .map(
            (f) => f.path.substring(root.path.length + 1).replaceAll(r'\', '/'),
          )
          // Hosting doesn't serve dotfiles, and one 404 fails the whole install.
          .where((p) => !p.split('/').any((part) => part.startsWith('.')))
          .where((p) => !p.endsWith('.symbols') && p != 'sw.js')
          .toList()
        ..sort();

  // The renderer differs per browser (and is large), so it is cached at
  // runtime when first loaded instead of precached.
  final precache = [
    './',
    for (final p in files)
      if (!p.startsWith('canvaskit/')) p,
  ];

  // Hash of every file's path and content hash.
  final manifest = [
    for (final p in files)
      '$p ${sha256.convert(File('${root.path}/$p').readAsBytesSync())}',
  ].join('\n');
  final version = sha256
      .convert(utf8.encode(manifest))
      .toString()
      .substring(0, 12);

  // Always start from the template so re-running is safe.
  final template = File('web/sw.js');
  File('${root.path}/sw.js').writeAsStringSync(
    template
        .readAsStringSync()
        .replaceFirst('__VERSION__', version)
        .replaceFirst(
          '__PRECACHE__',
          const JsonEncoder.withIndent('  ').convert(precache),
        ),
  );
  stdout.writeln('sw.js: version $version, ${precache.length} precached files');
}
