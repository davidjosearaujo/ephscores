import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Contact {
  const Contact({
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

  bool matches(String query) {
    final q = normalize(query);
    return normalize(title).contains(q) ||
        normalize(description).contains(q) ||
        number.contains(q.replaceAll(' ', ''));
  }
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
