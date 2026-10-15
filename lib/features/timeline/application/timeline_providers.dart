import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../../growth/data/growth_repository.dart';
import '../data/timeline_repository.dart';
import 'timeline_reminders.dart';

/// How far around today an item counts as «دلوقتي».
const timelineNowWindowDays = 14;

class TimelineData {
  const TimelineData({required this.child, required this.items, required this.done, this.country = 'EG'});

  final GrowthChild? child;
  final List<TimelineItem> items;
  final Set<String> done;
  final String country;

  bool get hasVaccines => items.any((i) => i.kind == TimelineKind.vaccine);

  int? get ageDays {
    final birth = child?.birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(birth.year, birth.month, birth.day)).inDays;
  }

  bool isOverdue(TimelineItem item) =>
      item.kind == TimelineKind.vaccine && !done.contains(item.id) && item.ageDays < ageDays! - timelineNowWindowDays;

  /// Due around now, plus vaccines that were missed.
  List<TimelineItem> get current {
    final age = ageDays;
    if (age == null) return const [];
    return [
      for (final i in items)
        if ((i.ageDays - age).abs() <= timelineNowWindowDays || isOverdue(i)) i,
    ];
  }

  List<TimelineItem> get upcoming {
    final age = ageDays;
    if (age == null) return const [];
    return [for (final i in items) if (i.ageDays > age + timelineNowWindowDays) i];
  }

  List<TimelineItem> get past {
    final age = ageDays;
    if (age == null) return const [];
    return [
      for (final i in items.reversed)
        if (i.ageDays < age - timelineNowWindowDays && !isOverdue(i)) i,
    ];
  }

  /// The single most useful item for the home card.
  TimelineItem? get highlight {
    final c = current;
    if (c.isEmpty) return upcoming.isNotEmpty && upcoming.first.ageDays - ageDays! <= 30 ? upcoming.first : null;
    final vaccine = c.where((i) => i.kind == TimelineKind.vaccine && !done.contains(i.id));
    return vaccine.isNotEmpty ? vaccine.first : c.first;
  }
}

final timelineDataProvider = FutureProvider.autoDispose<TimelineData>((ref) async {
  final child = await ref.watch(growthRepositoryProvider).fetchActiveChild();
  if (child == null) return const TimelineData(child: null, items: [], done: {});
  final repo = ref.watch(timelineRepositoryProvider);
  final picked = ref.read(prefsServiceProvider).getVaccineCountry();
  final country = picked != null && vaccineCountries.containsKey(picked) ? picked : await repo.fetchDefaultCountry();
  final results = await Future.wait([repo.fetchItems(country), repo.fetchDone(child.id)]);
  final data = TimelineData(
    child: child,
    items: results[0] as List<TimelineItem>,
    done: results[1] as Set<String>,
    country: country,
  );
  if (ref.read(prefsServiceProvider).getTimelineReminders()) {
    unawaited(TimelineReminders.instance.sync(data));
  }
  return data;
});

/// «كمان 3 أيام» / «النهارده» / «من 5 أيام».
String timelineWhen(int itemAgeDays, int ageDays) {
  final diff = itemAgeDays - ageDays;
  if (diff == 0) return 'النهارده';
  final n = diff.abs();
  final unit = switch (n) {
    1 => 'يوم',
    2 => 'يومين',
    <= 10 => '$n أيام',
    < 60 => '$n يوم',
    _ => '${(n / 30.4).round()} شهور',
  };
  return diff > 0 ? 'كمان $unit' : 'من $unit';
}
