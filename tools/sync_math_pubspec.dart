// ignore_for_file: avoid_print
// Regenerates math asset entries in pubspec.yaml from disk (ASCII folders only).
// Run: dart run tools/sync_math_pubspec.dart

import 'dart:convert';
import 'dart:io';

void main() {
  const manifestLine = '    - assets/math/manifest.json';
  final mathRoot = Directory('assets/math/packages');
  final lines = <String>[manifestLine];

  if (mathRoot.existsSync()) {
    final pkgs = mathRoot
        .listSync()
        .whereType<Directory>()
        .map((d) => d.path.split(Platform.pathSeparator).last)
        .where((name) => RegExp(r'^[a-z0-9_]+$').hasMatch(name))
        .toList()
      ..sort();
    for (final pkg in pkgs) {
      final pkgDir = Directory('${mathRoot.path}/$pkg');
      final slides = pkgDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split(Platform.pathSeparator).last)
          .where((n) => n.startsWith('slide_'))
          .toList()
        ..sort();
      for (final slide in slides) {
        lines.add('    - assets/math/packages/$pkg/$slide/');
      }
    }
  }

  final pubspec = File('pubspec.yaml');
  final content = pubspec.readAsStringSync(encoding: utf8);
  const startMarker = '    - assets/math/manifest.json';
  final fontsIdx = content.indexOf('\n  fonts:');
  final start = content.indexOf(startMarker);
  if (start < 0 || fontsIdx < 0) {
    stderr.writeln('Could not find math assets block in pubspec.yaml');
    exit(1);
  }
  final end = fontsIdx;

  final newBlock = '${lines.join('\n')}\n';
  pubspec.writeAsStringSync(
    content.replaceRange(start, end, newBlock),
    encoding: utf8,
  );
  print('pubspec.yaml: ${lines.length - 1} math asset lines');
}
