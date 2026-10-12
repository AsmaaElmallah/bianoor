import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

class GrowthChild {
  const GrowthChild({required this.id, required this.name, this.gender, this.birthDate});

  final String id;
  final String name;
  final String? gender;
  final DateTime? birthDate;

  bool get isReady => gender != null && birthDate != null;
  bool get isMale => gender == 'male';
}

class GrowthMeasurement {
  const GrowthMeasurement({required this.id, required this.measuredOn, this.weightKg, this.lengthCm});

  factory GrowthMeasurement.fromRow(Map<String, dynamic> row) => GrowthMeasurement(
        id: row['id'] as String,
        measuredOn: DateTime.parse(row['measured_on'] as String),
        weightKg: (row['weight_kg'] as num?)?.toDouble(),
        lengthCm: (row['length_cm'] as num?)?.toDouble(),
      );

  final String id;
  final DateTime measuredOn;
  final double? weightKg;
  final double? lengthCm;
}

final growthRepositoryProvider = Provider<GrowthRepository>((ref) => GrowthRepository());

class GrowthRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  String? get _userId => SupabaseBootstrap.isReady ? SupabaseBootstrap.client.auth.currentUser?.id : null;

  Future<GrowthChild?> fetchActiveChild() async {
    if (!await _ready() || _userId == null) return null;
    final row = await SupabaseBootstrap.client
        .from('children')
        .select('id, name, gender, birth_date')
        .eq('user_id', _userId!)
        .eq('is_active', true)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return GrowthChild(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      gender: row['gender'] as String?,
      birthDate: DateTime.tryParse(row['birth_date'] as String? ?? ''),
    );
  }

  Future<void> saveChildBasics(String childId, {required DateTime birthDate, required String gender}) async {
    await SupabaseBootstrap.client
        .from('children')
        .update({'birth_date': _date(birthDate), 'gender': gender}).eq('id', childId);
  }

  Future<List<GrowthMeasurement>> fetchMeasurements(String childId) async {
    final rows = await SupabaseBootstrap.client
        .from('growth_measurements')
        .select('id, measured_on, weight_kg, length_cm')
        .eq('child_id', childId)
        .order('measured_on');
    return [for (final r in List<Map<String, dynamic>>.from(rows as List)) GrowthMeasurement.fromRow(r)];
  }

  Future<void> saveMeasurement(
    String childId, {
    required DateTime measuredOn,
    double? weightKg,
    double? lengthCm,
  }) async {
    await SupabaseBootstrap.client.from('growth_measurements').upsert(
      {
        'user_id': _userId,
        'child_id': childId,
        'measured_on': _date(measuredOn),
        'weight_kg': weightKg,
        'length_cm': lengthCm,
      },
      onConflict: 'child_id,measured_on',
    );
  }

  Future<void> deleteMeasurement(String id) async {
    await SupabaseBootstrap.client.from('growth_measurements').delete().eq('id', id);
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
