import 'dart:convert';
import 'dart:io';

import 'package:ephscores/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// pubspec.yaml holds the app's identity; every platform manifest must agree.
void main() {
  final info = AppInfo.fromPubspec(File('pubspec.yaml').readAsStringSync());
  String read(String path) => File(path).readAsStringSync();

  test('pubspec metadata parses', () {
    expect(info.name, 'EPHScores');
    expect(info.applicationId, 'com.davidaraujo.ephscores');
    expect(info.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    expect(info.build, matches(RegExp(r'^\d+$')));
    expect(info.developer, 'David Araújo');
    expect(info.developerUrl, startsWith('https://'));
    expect(info.repository, startsWith('https://codeberg.org/'));
  });

  test('version without a build number', () {
    final i = AppInfo.fromPubspec('''
version: 1.2.3
description: d
app_info: {display_name: A, application_id: a.b, developer: D}
homepage: "  "
''');
    expect(
      (i.version, i.build, i.fullVersion, i.homepage),
      ('1.2.3', '', '1.2.3', null),
    );
  });

  test('Android', () {
    final gradle = read('android/app/build.gradle.kts');
    expect(gradle, contains('applicationId = "${info.applicationId}"'));
    expect(gradle, contains('namespace = "${info.applicationId}"'));
    expect(
      read('android/app/src/main/AndroidManifest.xml'),
      contains('android:label="${info.name}"'),
    );
  });

  test('iOS', () {
    expect(
      read('ios/Runner.xcodeproj/project.pbxproj'),
      contains('PRODUCT_BUNDLE_IDENTIFIER = ${info.applicationId};'),
    );
    expect(
      read('ios/Runner/Info.plist'),
      matches(RegExp('CFBundleDisplayName</key>\\s*<string>${info.name}<')),
    );
  });

  test('web', () {
    final manifest = jsonDecode(read('web/manifest.json')) as Map;
    expect(manifest['name'], info.name);
    expect(manifest['short_name'], info.name);
    expect(manifest['description'], info.description);
    final html = read('web/index.html');
    expect(html, contains('<title>${info.name}</title>'));
    expect(html, contains('content="${info.description}"'));
    expect(
      html,
      contains('apple-mobile-web-app-title" content="${info.name}"'),
    );
  });
}
