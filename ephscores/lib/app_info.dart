import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// The app's identity, read from the bundled pubspec.yaml so the version and
/// metadata are maintained in one place.
class AppInfo {
  const AppInfo({
    required this.name,
    required this.description,
    required this.version,
    required this.build,
    required this.applicationId,
    required this.developer,
    this.developerUrl,
    this.homepage,
    this.repository,
  });

  /// Parses pubspec.yaml content.
  factory AppInfo.fromPubspec(String yaml) {
    final doc = loadYaml(yaml) as YamlMap;
    final info = doc['app_info'] as YamlMap;
    // "2.0.0+9": version name, then the optional build number.
    final full = '${doc['version']}';
    final plus = full.indexOf('+');
    final version = plus == -1 ? full : full.substring(0, plus);
    final build = plus == -1 ? '' : full.substring(plus + 1);
    String? optional(Object? value) {
      final s = (value as String?)?.trim();
      return s == null || s.isEmpty ? null : s;
    }

    return AppInfo(
      name: info['display_name'] as String,
      description: doc['description'] as String,
      version: version,
      build: build,
      applicationId: info['application_id'] as String,
      developer: info['developer'] as String,
      developerUrl: optional(info['developer_url']),
      homepage: optional(doc['homepage']),
      repository: optional(doc['repository']),
    );
  }

  static Future<AppInfo>? _cached;

  /// Loads (once) from the bundled pubspec.
  static Future<AppInfo> load() => _cached ??= rootBundle
      .loadString('pubspec.yaml')
      .then(AppInfo.fromPubspec);

  final String name;
  final String description;
  final String version;

  /// Build number (Android versionCode / iOS CFBundleVersion); may be empty.
  final String build;
  final String applicationId;
  final String developer;

  /// Developer's website; the name links to it.
  final String? developerUrl;
  final String? homepage;
  final String? repository;

  /// "2.0.0 (9)".
  String get fullVersion => build.isEmpty ? version : '$version ($build)';
}
