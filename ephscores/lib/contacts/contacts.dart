import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Contact {
  Contact({
    required this.title,
    required this.description,
    required this.number,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    title: json['title'] as String,
    description: json['description'] as String,
    number: json['number'] as String,
  );

  final String title;
  final String description;
  final String number;

  /// Nine-digit numbers grouped in threes; short codes are left as they are.
  String get formattedNumber => number.length == 9
      ? '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}'
      : number;

  /// Accent-free lower-case text to search in, computed once per contact.
  late final String _searchText = normalize('$title $description');

  /// Whether this contact matches [query], already passed through [normalize].
  bool matches(String query) =>
      _searchText.contains(query) || number.contains(query.replaceAll(' ', ''));
}

/// Contacts matching [query], ignoring case and accents.
List<Contact> filterContacts(List<Contact> contacts, String query) {
  final q = normalize(query);
  return q.isEmpty
      ? contacts
      : [
          for (final c in contacts)
            if (c.matches(q)) c,
        ];
}

const _accents = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'é': 'e',
  'ê': 'e',
  'í': 'i',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ú': 'u',
  'ç': 'c',
};

/// Lower-cases and strips Portuguese accents so "saude" finds "Saúde".
String normalize(String s) =>
    s.toLowerCase().split('').map((c) => _accents[c] ?? c).join().trim();

Future<List<Contact>> loadContacts() async {
  final raw = await rootBundle.loadString('assets/Contacts.json');
  final list = (jsonDecode(raw) as Map<String, dynamic>)['contacts'] as List;
  return [for (final c in list) Contact.fromJson(c as Map<String, dynamic>)]
    ..sort((a, b) => normalize(a.title).compareTo(normalize(b.title)));
}
