// ignore_for_file: avoid_print
// Renames Arabic package folders to ASCII ids and updates manifest.json.
// Run: dart run tools/rename_math_packages.dart

import 'dart:convert';
import 'dart:io';

final _asciiId = RegExp(r'^[a-z0-9_]+$');

/// Maps legacy Arabic package ids to catalog ids in math_package_catalog.dart.
String? asciiIdForLegacyId(String id) {
  if (_asciiId.hasMatch(id)) return null;
  if (id.contains('الخرزات')) return 'beads_numeric';
  if (id.contains('العاشر')) return 'lesson_79_84';
  if (id.contains('التاسع')) return 'lesson_73_78';
  if (id.contains('الثامن')) return 'lesson_67_72';
  if (id.contains('السابع')) return 'lesson_61_66';
  if (id.contains('السادس')) return 'lesson_51_60';
  if (id.contains('الخامس')) return 'lesson_41_50';
  if (id.contains('الرابع')) return 'lesson_30_40';
  if (id.contains('الثالث')) return 'lesson_20_30';
  if (id.contains('الاول')) return 'lesson_01_10';
  return null;
}

void main() {
  final root = Directory('assets/math');
  final packagesDir = Directory('${root.path}/packages');
  final manifestFile = File('${root.path}/manifest.json');

  if (!manifestFile.existsSync()) {
    stderr.writeln('Missing ${manifestFile.path}');
    exit(1);
  }

  final manifest = jsonDecode(manifestFile.readAsStringSync(encoding: utf8))
      as Map<String, dynamic>;
  final packages = manifest['packages'] as List<dynamic>;

  final renames = <String, String>{};
  for (final raw in packages) {
    final pkg = raw as Map<String, dynamic>;
    final oldId = pkg['id'] as String;
    final newId = asciiIdForLegacyId(oldId);
    if (newId == null || newId == oldId) continue;
    renames[oldId] = newId;
  }

  if (renames.isEmpty) {
    print('No Arabic package ids in manifest — already migrated.');
    return;
  }

  for (final entry in renames.entries) {
    final oldId = entry.key;
    final newId = entry.value;
    final oldDir = Directory('${packagesDir.path}/$oldId');
    final newDir = Directory('${packagesDir.path}/$newId');

    if (oldDir.existsSync()) {
      if (newDir.existsSync()) {
        print('Skip rename $oldId -> $newId (target exists)');
      } else {
        oldDir.renameSync(newDir.path);
        print('Renamed folder: $oldId -> $newId');
      }
    } else if (!newDir.existsSync()) {
      print('WARN: missing folder for $oldId');
    }
  }

  for (final raw in packages) {
    final pkg = raw as Map<String, dynamic>;
    final oldId = pkg['id'] as String;
    final newId = renames[oldId];
    if (newId == null) continue;
    pkg['id'] = newId;
    final slides = pkg['slides'] as List<dynamic>? ?? [];
    for (final s in slides) {
      final slide = s as Map<String, dynamic>;
      final folder = slide['folder'] as String;
      slide['folder'] = folder.replaceAll('packages/$oldId/', 'packages/$newId/');
    }
  }

  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest),
    encoding: utf8,
  );
  print('Updated manifest.json (${renames.length} packages)');
}
