import 'package:bayanour/features/growth/domain/growth_calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Expected values are the published WHO percentiles (CDC/NCHS WHO tables).
  test('girls weight-for-age matches WHO percentiles', () {
    expect(growthValueAtZ(GrowthMetric.weight, false, 6, -1.6449), closeTo(5.97888, 0.005));
    expect(growthValueAtZ(GrowthMetric.weight, false, 6, 0), closeTo(7.297, 0.001));
    expect(growthValueAtZ(GrowthMetric.weight, false, 12, 1.6449), closeTo(10.99531, 0.005));
  });

  test('boys length-for-age matches WHO percentiles', () {
    expect(growthValueAtZ(GrowthMetric.length, true, 9, -2), closeTo(67.48217, 0.005));
    expect(growthValueAtZ(GrowthMetric.length, true, 9, 0), closeTo(71.9687, 0.001));
  });

  test('z-score and percentile round-trip', () {
    final z = growthZ(GrowthMetric.weight, false, 6, 5.97888);
    expect(z, closeTo(-1.645, 0.01));
    expect(percentileFromZ(z), closeTo(5, 0.2));
    expect(percentileFromZ(0), closeTo(50, 0.001));
  });

  test('reading flags only values outside -2..+2 SD', () {
    expect(readGrowth(GrowthMetric.weight, false, 6, 7.3).level, GrowthLevel.normal);
    expect(readGrowth(GrowthMetric.weight, false, 6, 5.2).level, GrowthLevel.watch);
    expect(readGrowth(GrowthMetric.weight, false, 6, 10).level, GrowthLevel.watch);
    expect(readGrowth(GrowthMetric.length, true, 9, 77).level, GrowthLevel.normal);
  });

  test('age in months', () {
    expect(ageInMonths(DateTime(2026, 1, 1), DateTime(2026, 7, 2)), closeTo(5.98, 0.05));
    expect(droppedOffCurve(0.2, -0.9), isTrue);
    expect(droppedOffCurve(0.2, -0.3), isFalse);
  });
}
