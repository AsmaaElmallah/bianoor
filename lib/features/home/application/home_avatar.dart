import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../shared/widgets/app_logo_avatar.dart';

/// Saved path of the mother's home-logo photo. Null keeps the Bayanour baby.
final homeAvatarPathProvider = StateProvider<String?>((ref) {
  final path = ref.read(prefsServiceProvider).getHomeAvatarPath();
  if (path == null || !File(path).existsSync()) return null;
  return path;
});

/// Opens the gallery, copies the photo into app storage, and remembers it.
/// Returns false when the mother dismisses the picker.
Future<bool> pickHomeAvatar(WidgetRef ref) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 85,
  );
  if (picked == null) return false;

  final dir = await getApplicationDocumentsDirectory();
  final dest = File('${dir.path}/home_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await File(picked.path).copy(dest.path);

  final prefs = ref.read(prefsServiceProvider);
  final previous = prefs.getHomeAvatarPath();
  await prefs.setHomeAvatarPath(dest.path);
  if (previous != null && previous != dest.path) {
    final old = File(previous);
    if (old.existsSync()) await old.delete();
  }
  ref.read(homeAvatarPathProvider.notifier).state = dest.path;
  return true;
}

/// Removes the saved photo so the home logo returns to the Bayanour baby.
Future<void> clearHomeAvatar(WidgetRef ref) async {
  final prefs = ref.read(prefsServiceProvider);
  final previous = prefs.getHomeAvatarPath();
  await prefs.clearHomeAvatarPath();
  if (previous != null) {
    final old = File(previous);
    if (old.existsSync()) await old.delete();
  }
  ref.read(homeAvatarPathProvider.notifier).state = null;
}

/// Circular home logo: the mother's photo when one is saved, otherwise the baby.
class HomeLogoAvatar extends ConsumerWidget {
  const HomeLogoAvatar({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(homeAvatarPathProvider);
    if (path == null) return AppLogoAvatar(size: size);
    return ClipOval(
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => AppLogoAvatar(size: size),
      ),
    );
  }
}
