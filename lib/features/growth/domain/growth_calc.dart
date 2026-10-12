import 'dart:math' as math;

import 'who_growth_data.dart';

enum GrowthMetric { weight, length }

enum GrowthLevel { normal, watch }

const maxGrowthMonths = 24.0;
const _daysPerMonth = 30.4375;

/// Reference percentile lines drawn on the chart (3rd, 15th, 50th, 85th, 97th).
const growthChartZ = [-1.881, -1.036, 0.0, 1.036, 1.881];

double ageInMonths(DateTime birth, DateTime on) => _day(on).difference(_day(birth)).inDays / _daysPerMonth;

DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

List<List<double>> _table(GrowthMetric metric, bool male) => switch (metric) {
      GrowthMetric.weight => male ? whoBoysWeightLms : whoGirlsWeightLms,
      GrowthMetric.length => male ? whoBoysLengthLms : whoGirlsLengthLms,
    };

/// L, M, S at a (fractional) age, linearly interpolated between whole months.
List<double> _lmsAt(GrowthMetric metric, bool male, double months) {
  final t = _table(metric, male);
  final m = months.clamp(0.0, maxGrowthMonths);
  final i = m.floor().clamp(0, t.length - 1);
  final j = math.min(i + 1, t.length - 1);
  final f = m - i;
  return [for (var k = 0; k < 3; k++) t[i][k] + (t[j][k] - t[i][k]) * f];
}

/// WHO LMS z-score.
double growthZ(GrowthMetric metric, bool male, double months, double value) {
  final lms = _lmsAt(metric, male, months);
  final l = lms[0], m = lms[1], s = lms[2];
  if (l.abs() < 1e-6) return math.log(value / m) / s;
  return (math.pow(value / m, l) - 1) / (l * s);
}

/// The measurement that sits on z-score [z] at [months].
double growthValueAtZ(GrowthMetric metric, bool male, double months, double z) {
  final lms = _lmsAt(metric, male, months);
  final l = lms[0], m = lms[1], s = lms[2];
  if (l.abs() < 1e-6) return m * math.exp(s * z);
  return m * math.pow(1 + l * s * z, 1 / l).toDouble();
}

/// Percentile (0–100) from a z-score.
double percentileFromZ(double z) => 100 * 0.5 * (1 + _erf(z / math.sqrt2));

double _erf(double x) {
  // Abramowitz–Stegun 7.1.26 (max error 1.5e-7).
  final sign = x < 0 ? -1 : 1;
  final ax = x.abs();
  final t = 1 / (1 + 0.3275911 * ax);
  final y = 1 -
      (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) *
          t *
          math.exp(-ax * ax);
  return sign * y;
}

class GrowthReading {
  const GrowthReading({required this.z, required this.percentile, required this.level, required this.label});

  final double z;
  final double percentile;
  final GrowthLevel level;
  final String label;
}

/// Plain-language reading — never a diagnosis; outside −2…+2 SD means «follow up with the doctor».
GrowthReading readGrowth(GrowthMetric metric, bool male, double months, double value) {
  final z = growthZ(metric, male, months, value);
  final p = percentileFromZ(z);
  if (z < -2) {
    return GrowthReading(
      z: z,
      percentile: p,
      level: GrowthLevel.watch,
      label: metric == GrowthMetric.weight
          ? 'الوزن أقل من المعتاد لسنه — يستاهل متابعة مع الطبيب'
          : 'الطول أقل من المعتاد لسنه — يستاهل متابعة مع الطبيب',
    );
  }
  if (z > 2 && metric == GrowthMetric.weight) {
    return GrowthReading(
      z: z,
      percentile: p,
      level: GrowthLevel.watch,
      label: 'الوزن أعلى من المعتاد لسنه — اسألي الطبيب في الزيارة الجاية',
    );
  }
  return GrowthReading(
    z: z,
    percentile: p,
    level: GrowthLevel.normal,
    label: metric == GrowthMetric.weight ? 'الوزن في المدى الطبيعي لسنه' : 'الطول في المدى الطبيعي لسنه',
  );
}

/// True when the child dropped a full z-score (≈ crossing two percentile lines) since the last reading.
bool droppedOffCurve(double previousZ, double latestZ) => previousZ - latestZ >= 1.0;
