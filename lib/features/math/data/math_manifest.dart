import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/math_slide.dart';

class MathManifestSlide {
  MathManifestSlide({
    required this.index,
    required this.folder,
    required this.durationSec,
    required this.imageCount,
  });

  factory MathManifestSlide.fromJson(Map<String, dynamic> json) {
    return MathManifestSlide(
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

class MathManifestPackage {
  MathManifestPackage({
    required this.id,
    required this.slideCount,
    required this.slides,
  });

  factory MathManifestPackage.fromJson(Map<String, dynamic> json) {
    final slidesJson = json['slides'] as List<dynamic>? ?? [];
    return MathManifestPackage(
      id: json['id'] as String,
      slideCount: json['slideCount'] as int? ?? slidesJson.length,
      slides: slidesJson
          .map((e) => MathManifestSlide.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final int slideCount;
  final List<MathManifestSlide> slides;

  MathManifestSlide? slideAt(int index) {
    if (index < 1 || index > slides.length) return null;
    return slides[index - 1];
  }
}

class MathManifest {
  MathManifest({required this.packages});

  factory MathManifest.fromJson(Map<String, dynamic> json) {
    final list = json['packages'] as List<dynamic>? ?? [];
    return MathManifest(
      packages: list
          .map((e) => MathManifestPackage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<MathManifestPackage> packages;

  MathManifestPackage? packageById(String id) {
    for (final p in packages) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class MathManifestRepository {
  MathManifest? _cached;

  Future<MathManifest> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/math/manifest.json');
    _cached = MathManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cached!;
  }

  /// Resolves image asset paths for a slide (sync — paths come from export layout).
  List<String> resolveImagePaths(MathManifestSlide slide) {
    final base = 'assets/math/${slide.folder}';
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

  Future<List<String>> _resolveImages(MathManifestSlide slide) async {
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

  Future<MathSlide?> buildSlide({
    required MathManifest manifest,
    required String packageId,
    required int slideIndex,
  }) async {
    final pkg = manifest.packageById(packageId);
    final entry = pkg?.slideAt(slideIndex);
    if (entry == null) return null;

    final images = await _resolveImages(entry);
    if (images.isEmpty) return null;

    String? audio;
    final audioPath = 'assets/math/${entry.folder}/audio.m4a';
    try {
      await rootBundle.load(audioPath);
      audio = audioPath;
    } catch (_) {}

    return MathSlide(
      packageId: packageId,
      slideIndex: slideIndex,
      assetFolder: entry.folder,
      durationSec: entry.durationSec,
      imageAssets: images,
      audioAsset: audio,
    );
  }
}
