import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../application/quran_curriculum_provider.dart';

class QuranScheduleInfo extends StatelessWidget {
  const QuranScheduleInfo({super.key, required this.state});

  final QuranCurriculumState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final khatmah = state.progress.currentKhatmahIndex;
    final daily = state.dailyRepetitions;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خطة الاستماع اليومية',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _Row(
            label: 'الجلسة الواحدة',
            value: 'نصف حزب (~15 دقيقة)',
          ),
          _Row(
            label: 'جلسات اليوم (الختمة $khatmah)',
            value: '$daily جلسات',
          ),
          _Row(
            label: 'معدل الحزب يومياً',
            value: _hizbPerDayLabel(daily),
          ),
          _Row(
            label: 'مدة إتمام الختمة',
            value: '${state.daysPerKhatmah} يوم',
          ),
          const SizedBox(height: 8),
          Text(
            _planFootnote(khatmah, daily),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _hizbPerDayLabel(int dailySessions) {
    if (dailySessions.isEven) return '${dailySessions ~/ 2} حزب';
    return '${dailySessions ~/ 2} حزب ونصف';
  }

  String _planFootnote(int khatmah, int daily) {
    return switch (khatmah) {
      1 =>
        'الختمة الأولى: جلستان يومياً (نصف حزب لكل جلسة) = حزب كامل يومياً. تُختم القرآن في نحو شهرين (60 يوماً).',
      2 =>
        'الختمة الثانية: 3 جلسات يومياً = نحو 40 يوماً للختمة.',
      3 =>
        'الختمة الثالثة: 4 جلسات يومياً = نحو 30 يوماً للختمة.',
      _ =>
        'الختمة $khatmah: 5 جلسات يومياً = نحو 24 يوماً للختمة.',
    };
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
