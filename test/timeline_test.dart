import 'package:bayanour/features/growth/data/growth_repository.dart';
import 'package:bayanour/features/timeline/application/timeline_providers.dart';
import 'package:bayanour/features/timeline/data/timeline_repository.dart';
import 'package:flutter_test/flutter_test.dart';

TimelineItem _item(String id, TimelineKind kind, int days) => TimelineItem(
      id: id,
      kind: kind,
      ageDays: days,
      title: id,
      body: '',
      tips: const [],
      sourceName: '',
    );

void main() {
  final now = DateTime.now();
  final child = GrowthChild(
    id: 'c',
    name: 'x',
    gender: 'male',
    birthDate: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 100)),
  );
  final items = [
    _item('m2', TimelineKind.development, 60),
    _item('m3', TimelineKind.development, 95),
    _item('m4', TimelineKind.development, 120),
    _item('m6', TimelineKind.feeding, 180),
  ];

  test('current / upcoming / past split for a 100-day-old', () {
    final d = TimelineData(child: child, items: items, done: const {});
    expect(d.ageDays, 100);
    expect(d.current.map((i) => i.id), ['m3']);
    expect(d.past.map((i) => i.id), ['m2']);
    expect(d.upcoming.map((i) => i.id), ['m4', 'm6']);
    expect(d.highlight?.id, 'm3');
  });

  test('timelineWhen wording', () {
    expect(timelineWhen(100, 100), 'النهارده');
    expect(timelineWhen(103, 100), 'كمان 3 أيام');
    expect(timelineWhen(98, 100), 'من يومين');
  });
}
