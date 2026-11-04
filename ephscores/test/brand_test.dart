import 'dart:io';
import 'dart:typed_data';

import 'package:ephscores/theme.dart';
import 'package:ephscores/ui/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

String hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';

/// Width and height from a PNG's header.
(int, int) pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes.sublist(16, 24)));
  return (data.getUint32(0), data.getUint32(4));
}

void main() {
  group('logo.svg', () {
    final svg = File(logoAsset).readAsStringSync();

    test('uses the app palette, which the animation looks up by value', () {
      for (final c in [Palette.navy, ...logoArmColors, Colors.white]) {
        expect(svg, contains('"${hex(c)}"'), reason: hex(c));
      }
    });

    test('keeps the structure the icon generator relies on', () {
      for (final id in ['badge', 'star', 'star-shape', 'arms-lower']) {
        expect(svg, contains('id="$id"'), reason: id);
      }
    });
  });

  group('generated icons', () {
    test('have the expected sizes', () {
      const expected = {
        'assets/icon/app_icon.png': 1024,
        'assets/icon/app_icon_foreground.png': 1024,
        'assets/icon/app_icon_monochrome.png': 1024,
        'assets/icon/play_store_512.png': 512,
        'web/icons/Icon-192.png': 192,
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-maskable-192.png': 192,
        'web/icons/Icon-maskable-512.png': 512,
        'web/icons/apple-touch-icon.png': 180,
        'web/favicon.png': 64,
      };
      for (final MapEntry(key: path, value: size) in expected.entries) {
        expect(pngSize(path), (size, size), reason: path);
      }
    });
  });

  group('widgets', () {
    testWidgets('AppLogo is a single image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppLogo(size: 64))),
      );
      await tester.pump();
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('EPHScores'), findsOneWidget);
    });

    testWidgets('LogoReveal lights the arms, then settles on one image', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LogoReveal(size: 64))),
      );
      // Unlit logo plus one layer per coloured arm.
      expect(find.byType(SvgPicture), findsNWidgets(1 + logoArmColors.length));
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('LogoReveal is static when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: Scaffold(body: LogoReveal(size: 64))),
        ),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('Wordmark spells the app name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Wordmark())),
      );
      expect(find.text('EPHScores', findRichText: true), findsOneWidget);
    });
  });
}
