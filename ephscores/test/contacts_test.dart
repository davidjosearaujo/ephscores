import 'dart:convert';
import 'dart:io';

import 'package:ephscores/contacts/contacts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final contacts = [
    Contact(
      title: 'Saúde 24',
      description: 'Aconselhamento clínico',
      number: '808242424',
    ),
    Contact(
      title: 'SOS Criança',
      description: 'Apoio a menores',
      number: '116111',
    ),
    Contact(
      title: 'Linha Abraço',
      description: 'Apoio emocional',
      number: '800225115',
    ),
  ];

  List<String> search(String q) =>
      filterContacts(contacts, q).map((c) => c.title).toList();

  test('ignores case and accents', () {
    expect(search('saude'), ['Saúde 24']);
    expect(search('CRIANCA'), ['SOS Criança']);
  });

  test('searches descriptions and numbers', () {
    expect(search('apoio'), ['SOS Criança', 'Linha Abraço']);
    expect(search('116111'), ['SOS Criança']);
    expect(search('808 242'), ['Saúde 24']);
  });

  test('empty query keeps everything, no match gives nothing', () {
    expect(search(''), hasLength(3));
    expect(search('   '), hasLength(3));
    expect(search('zzz'), isEmpty);
  });

  test('formats nine-digit numbers only', () {
    expect(contacts[0].formattedNumber, '808 242 424');
    expect(contacts[1].formattedNumber, '116111');
  });

  test('the bundled contacts file parses', () {
    final json = jsonDecode(File('assets/Contacts.json').readAsStringSync());
    final parsed = [
      for (final c in (json as Map)['contacts'] as List)
        Contact.fromJson(c as Map<String, dynamic>),
    ];
    expect(parsed, isNotEmpty);
    expect(parsed.every((c) => c.number.isNotEmpty), isTrue);
  });
}
