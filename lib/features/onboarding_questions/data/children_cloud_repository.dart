import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/baby_profile_model.dart';

class CloudChild {
  const CloudChild({
    required this.id,
    required this.name,
    required this.ageRangeIndex,
    this.gender,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int ageRangeIndex;
  final String? gender;
  final bool isActive;
}

final childrenCloudRepositoryProvider = Provider<ChildrenCloudRepository>((ref) {
  return ChildrenCloudRepository();
});

/// Active child for the signed-in parent (null if offline / none).
final activeChildProvider = FutureProvider<CloudChild?>((ref) {
  return ref.watch(childrenCloudRepositoryProvider).fetchActiveChild();
});

class ChildrenCloudRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<String?> _userId() async {
    if (!await _ready()) return null;
    return SupabaseBootstrap.client.auth.currentUser?.id;
  }

  Future<CloudChild?> fetchActiveChild() async {
    final userId = await _userId();
    if (userId == null) return null;
    try {
      final row = await SupabaseBootstrap.client
          .from('children')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return _fromRow(row);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Children] fetch active failed: $e\n$st');
      return null;
    }
  }

  Future<List<CloudChild>> fetchMyChildren() async {
    final userId = await _userId();
    if (userId == null) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('children')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      return [
        for (final row in List<Map<String, dynamic>>.from(rows as List))
          _fromRow(row),
      ];
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Children] list failed: $e\n$st');
      return [];
    }
  }

  /// Upserts active child from onboarding profile; deactivates other children.
  Future<CloudChild?> upsertFromProfile(BabyProfile profile) async {
    final userId = await _userId();
    if (userId == null) return null;

    try {
      final existing = await fetchActiveChild();
      final payload = {
        'user_id': userId,
        'name': profile.name.trim(),
        'gender': profile.gender == BabyGender.male ? 'male' : 'female',
        'age_range_index': BabyAgeRange.values.indexOf(profile.ageRange),
        'is_active': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      Map<String, dynamic> row;
      if (existing != null) {
        row = await SupabaseBootstrap.client
            .from('children')
            .update(payload)
            .eq('id', existing.id)
            .select()
            .single();
      } else {
        row = await SupabaseBootstrap.client
            .from('children')
            .insert(payload)
            .select()
            .single();
      }
      return _fromRow(row);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Children] upsert failed: $e\n$st');
      return null;
    }
  }

  CloudChild _fromRow(Map<String, dynamic> row) {
    return CloudChild(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      ageRangeIndex: (row['age_range_index'] as int?) ?? 0,
      gender: row['gender'] as String?,
      isActive: (row['is_active'] as bool?) ?? true,
    );
  }
}
