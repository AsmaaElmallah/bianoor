import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/visual_slide.dart';

class VisualManifestSlide {
  VisualManifestSlide({
    required this.index,
    required this.folder,
    required this.durationSec,
    required this.imageCount,
  });

  factory VisualManifestSlide.fromJson(Map<String, dynamic> json) {
    return VisualManifestSlide(
      index: json['index'] as int,
      folder: json['folder'] as String,
      durationSec: (json['durationSec'] as num).toDouble(),
      imageCount: json['imageCount'] as int? ?? 1,
    );
  }

  final int index;
  final String folder;
  final double durationSec;
  final int imageCount;
}

class VisualManifestPackage {
  VisualManifestPackage({
    required this.id,
    required this.slideCount,
    required this.slides,
    this.sourceFile,
  });

  factory VisualManifestPackage.fromJson(Map<String, dynamic> json) {
    final slidesJson = json['slides'] as List<dynamic>? ?? [];
    return VisualManifestPackage(
      id: json['id'] as String,
      slideCount: json['slideCount'] as int? ?? slidesJson.length,
      sourceFile: json['sourceFile'] as String?,
      slides: slidesJson
          .map((e) => VisualManifestSlide.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final int slideCount;
  final String? sourceFile;
  final List<VisualManifestSlide> slides;

  VisualManifestSlide? slideAt(int index) {
    if (index < 1 || index > slides.length) return null;
    return slides[index - 1];
  }
}

class VisualManifest {
  VisualManifest({required this.packages});

  factory VisualManifest.fromJson(Map<String, dynamic> json) {
    final list = json['packages'] as List<dynamic>? ?? [];
    return VisualManifest(
      packages: list
          .map((e) => VisualManifestPackage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<VisualManifestPackage> packages;

  VisualManifestPackage? packageById(String id) {
    for (final p in packages) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class VisualManifestRepository {
  VisualManifest? _cached;

  Future<VisualManifest> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/visual/manifest.json');
    _cached = VisualManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cached!;
  }

  List<String> resolveImagePaths(VisualManifestSlide slide) {
    final base = 'assets/visual/${slide.folder}';
    const exts = ['png', 'jpeg', 'jpg'];
    final images = <String>[];

    void tryPaths(String prefix) {
      for (final ext in exts) {
        images.add('$base/$prefix.$ext');
      }
    }

    if (slide.imageCount <= 1) {
      tryPaths('image');
      return images;
    }

    tryPaths('image');
    for (var i = 1; i < slide.imageCount; i++) {
      tryPaths('image_$i');
    }
    return images;
  }

  Future<String?> _firstLoadablePath(List<String> candidates) async {
    for (final path in candidates) {
      try {
        await rootBundle.load(path);
        return path;
      } catch (_) {}
    }
    return null;
  }

  Future<List<String>> _resolveImages(VisualManifestSlide slide) async {
    final candidates = resolveImagePaths(slide);
    final images = <String>[];

    if (slide.imageCount <= 1) {
      final hit = await _firstLoadablePath(candidates);
      if (hit != null) images.add(hit);
      return images;
    }

    final groups = <int, List<String>>{};
    for (final path in candidates) {
      final name = path.split('/').last;
      if (name.startsWith('image_')) {
        final idx = int.tryParse(name.split('.').first.replaceFirst('image_', '')) ?? 0;
        groups.putIfAbsent(idx, () => []).add(path);
      } else if (name.startsWith('image.')) {
        groups.putIfAbsent(0, () => []).add(path);
      }
    }

    final keys = groups.keys.toList()..sort();
    for (final key in keys) {
      final hit = await _firstLoadablePath(groups[key]!);
      if (hit != null) images.add(hit);
    }
    return images;
  }

  Future<VisualSlide?> buildSlide({
    required VisualManifest manifest,
    required String packageId,
    required int slideIndex,
  }) async {
    final pkg = manifest.packageById(packageId);
    final entry = pkg?.slideAt(slideIndex);
    if (entry == null) return null;

    final images = await _resolveImages(entry);
    if (images.isEmpty) return null;

    String? audio;
    final audioPath = 'assets/visual/${entry.folder}/audio.m4a';
    try {
      await rootBundle.load(audioPath);
      audio = audioPath;
    } catch (_) {}

    return VisualSlide(
      packageId: packageId,
      slideIndex: slideIndex,
      assetFolder: entry.folder,
      durationSec: entry.durationSec,
      imageAssets: images,
      audioAsset: audio,
    );
  }
}
