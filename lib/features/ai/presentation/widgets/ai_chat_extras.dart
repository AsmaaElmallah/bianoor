import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/ai_models.dart';

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
