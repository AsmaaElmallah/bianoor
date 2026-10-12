import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/growth_repository.dart';

class GrowthData {
  const GrowthData({required this.child, required this.measurements});

  final GrowthChild? child;
  final List<GrowthMeasurement> measurements;
}

final growthDataProvider = FutureProvider.autoDispose<GrowthData>((ref) async {
  final repo = ref.watch(growthRepositoryProvider);
  final child = await repo.fetchActiveChild();
  if (child == null) return const GrowthData(child: null, measurements: []);
  return GrowthData(child: child, measurements: await repo.fetchMeasurements(child.id));
});
