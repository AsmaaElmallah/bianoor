import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../application/ai_providers.dart';
import '../../data/ai_models.dart';

/// Pinned «رسالة النهارده» — today's tip from the daily plan (no extra AI call).
class AiPinnedTip extends ConsumerWidget {
  const AiPinnedTip({super.key, required this.babyName, required this.onAsk, required this.onClose});

  final String? babyName;
  final ValueChanged<String> onAsk;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tip = withBabyName(ref.watch(aiDailyPlanProvider).valueOrNull?.plan?.tip ?? '', babyName).trim();
    if (tip.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: AppColors.primaryContainer,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: () => onAsk('عايزة أعرف أكتر عن رسالة النهارده: $tip'),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Symbols.push_pin, size: 18, color: AppColors.primary, fill: 1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رسالة النهارده',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tip,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onPrimaryContainer, height: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'دوسي عشان نتكلم عنها ←',
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'إخفاء',
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(Symbols.close, size: 18, color: AppColors.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AiShortcut {
  const AiShortcut(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class AiShortcutsRow extends StatelessWidget {
  const AiShortcutsRow({super.key, required this.shortcuts, required this.enabled});

  final List<AiShortcut> shortcuts;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: shortcuts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = shortcuts[i];
          return ActionChip(
            avatar: Icon(s.icon, size: 18, color: AppColors.primary),
            label: Text(s.label),
            backgroundColor: AppColors.surfaceContainerLowest,
            side: const BorderSide(color: AppColors.outline),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
            onPressed: enabled ? s.onTap : null,
          );
        },
      ),
    );
  }
}

const _commonAllergies = ['بيض', 'ألبان', 'قمح', 'سمك', 'فول سوداني', 'مكسرات', 'سمسم'];

/// «وجبة النهارده» form. Returns null when cancelled.
Future<AiMealRequest?> showAiMealSheet(BuildContext context, {required int ageRangeIndex}) {
  return showModalBottomSheet<AiMealRequest>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _MealSheet(ageRangeIndex: ageRangeIndex),
  );
}

class _MealSheet extends StatefulWidget {
  const _MealSheet({required this.ageRangeIndex});

  final int ageRangeIndex;

  @override
  State<_MealSheet> createState() => _MealSheetState();
}

class _MealSheetState extends State<_MealSheet> {
  final _ingredients = TextEditingController();
  final _other = TextEditingController();
  final _allergies = <String>{};

  @override
  void dispose() {
    _ingredients.dispose();
    _other.dispose();
    super.dispose();
  }

  void _submit() {
    final other = _other.text.split(RegExp('[،,]')).map((s) => s.trim()).where((s) => s.isNotEmpty);
    Navigator.of(context).pop(AiMealRequest(
      ingredients: _ingredients.text.trim(),
      allergies: {..._allergies, ...other}.toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tooYoung = widget.ageRangeIndex == 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('وجبة النهارده 🍲', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (tooYoung) ...[
              Text(
                'في السن ده الرضاعة (طبيعية أو صناعي) كفاية تماماً. الأكل الصلب بيبدأ عند حوالي 6 شهور '
                'لما الطفل يقعد بسند ويثبت راسه — حسب توصيات منظمة الصحة العالمية.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('تمام')),
            ] else ...[
              Text(
                'قوليلي إيه الموجود عندك، وهقترح وجبة مناسبة لسنه بالكمية وطريقة الحفظ.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ingredients,
                maxLength: 300,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'إيه الموجود في البيت؟',
                  hintText: 'مثلاً: بطاطس، جزر، فراخ، رز، موز',
                ),
              ),
              const SizedBox(height: 4),
              Text('عنده حساسية من؟', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _commonAllergies)
                    FilterChip(
                      label: Text(a),
                      selected: _allergies.contains(a),
                      onSelected: (on) => setState(() => on ? _allergies.add(a) : _allergies.remove(a)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _other,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'حساسية تانية (اختياري)', hintText: 'افصلي بينهم بفاصلة'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Symbols.restaurant),
                label: const Text('اقترحي وجبة'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
