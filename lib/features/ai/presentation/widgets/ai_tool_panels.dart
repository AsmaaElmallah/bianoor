import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/storage/prefs_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../growth/application/growth_providers.dart';
import '../../../growth/data/growth_repository.dart';
import '../../../growth/domain/growth_calc.dart';
import '../../../timeline/application/timeline_providers.dart';
import '../../application/ai_providers.dart';
import '../../data/ai_models.dart';

enum AiChatTool { growth, stool, plan, meal }

/// Full-height tool panel that stays inside the chat shell.
class AiToolPanel extends ConsumerWidget {
  const AiToolPanel({
    super.key,
    required this.tool,
    required this.onClose,
    this.onMealReady,
  });

  final AiChatTool tool;
  final VoidCallback onClose;
  final ValueChanged<AiMealRequest>? onMealReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          _ToolHeader(
            title: switch (tool) {
              AiChatTool.growth => 'نموه',
              AiChatTool.stool => 'لون البراز',
              AiChatTool.plan => 'خطة النهارده',
              AiChatTool.meal => 'وجبة النهارده',
            },
            onClose: onClose,
          ),
          Expanded(
            child: switch (tool) {
              AiChatTool.growth => _GrowthFlow(onDone: onClose),
              AiChatTool.stool => _StoolFlow(onDone: onClose),
              AiChatTool.plan => _PlanFlow(onDone: onClose),
              AiChatTool.meal => _MealFlow(
                  onDone: onClose,
                  onReady: (meal) {
                    onClose();
                    onMealReady?.call(meal);
                  },
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _ToolHeader extends StatelessWidget {
  const _ToolHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.9))),
        boxShadow: AppShadows.clayLift,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.onSurface),
            tooltip: 'رجوع للشات',
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Growth
// ---------------------------------------------------------------------------

class _GrowthFlow extends ConsumerStatefulWidget {
  const _GrowthFlow({required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<_GrowthFlow> createState() => _GrowthFlowState();
}

class _GrowthFlowState extends ConsumerState<_GrowthFlow> {
  final _weight = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  Future<void> _saveWeight(GrowthChild child) async {
    final kg = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    if (kg == null || kg < 1 || kg > 30) return;
    setState(() => _saving = true);
    try {
      await ref.read(growthRepositoryProvider).saveMeasurement(
            child.id,
            measuredOn: DateTime.now(),
            weightKg: kg,
          );
      ref.invalidate(growthDataProvider);
      _weight.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(growthDataProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('تعذّر تحميل النمو')),
      data: (data) {
        final child = data.child;
        if (child == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: _BotLine(text: 'سجّلي دخولك وكمّلي بيانات الطفل الأول.'),
          );
        }
        if (!child.isReady) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _BotLine(text: 'محتاجة تاريخ الميلاد والنوع عشان أحسب منحنى WHO.'),
              const SizedBox(height: 12),
              _ChildBasicsForm(
                child: child,
                onSaved: () {
                  ref.invalidate(growthDataProvider);
                  ref.invalidate(timelineDataProvider);
                },
              ),
              TextButton(onPressed: widget.onDone, child: const Text('رجوع')),
            ],
          );
        }

        GrowthMeasurement? latest;
        for (final m in data.measurements.reversed) {
          if (m.weightKg != null) {
            latest = m;
            break;
          }
        }
        final months = ageInMonths(child.birthDate!, latest?.measuredOn ?? DateTime.now());
        final ideal = growthValueAtZ(GrowthMetric.weight, child.isMale, months, 0);
        final reading = latest?.weightKg == null
            ? null
            : readGrowth(GrowthMetric.weight, child.isMale, months, latest!.weightKg!);

        String verdict;
        if (reading == null) {
          verdict = 'اكتبي وزنه بالكيلو وأقولك تمام ولا محتاج متابعة.';
        } else if (reading.level == GrowthLevel.normal) {
          verdict = 'وزنه حلو وفي المدى الطبيعي لسنه حسب منظمة الصحة العالمية.';
        } else {
          verdict = 'وزنه بره المدى المعتاد لسنه — يستاهل متابعة مع دكتور تغذية أو طبيب الأطفال.';
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const _BotLine(text: 'متابعة منحنى الوزن ببساطة — من غير شارت معقّد.'),
            const SizedBox(height: 12),
            _InfoCard(
              accent: AppColors.tertiary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'منظمة الصحة العالمية WHO',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.tertiaryDim,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.tertiaryContainer,
                        child: Icon(Symbols.monitoring, color: AppColors.tertiaryDim, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'متابعة منحنيات النمو',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'سجّلي الوزن وشوفي مكانه على المدى الطبيعي من غير قلق.',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'الوزن المثالي: ${ideal.toStringAsFixed(2)} كجم',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.tertiaryDim,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'عمر الرضيع: ${months.round()} شهر',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _AgeBar(months: months),
                  const SizedBox(height: 14),
                  Text(verdict, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.4)),
                  if (latest?.weightKg != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'آخر وزن مسجّل: ${latest!.weightKg!.toStringAsFixed(2)} كجم',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(
                labelText: 'وزنه دلوقتي (كجم)',
                hintText: 'مثلاً 5.2',
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              style: _primaryButton(),
              onPressed: _saving ? null : () => _saveWeight(child),
              child: Text(_saving ? '...' : 'احسبي'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: widget.onDone, child: const Text('رجوع للشات')),
          ],
        );
      },
    );
  }
}

class _AgeBar extends StatelessWidget {
  const _AgeBar({required this.months});

  final double months;

  @override
  Widget build(BuildContext context) {
    final t = (months / maxGrowthMonths).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(-1 + 2 * t, 0),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('0 شهور\n(الولادة)', style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.start),
            const Spacer(),
            Text('12 شهر', style: Theme.of(context).textTheme.labelSmall),
            const Spacer(),
            Text('24 شهر\n(سنتين)', style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.end),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stool
// ---------------------------------------------------------------------------

class _StoolSwatch {
  const _StoolSwatch(this.color, this.name, this.ok, this.note);

  final Color color;
  final String name;
  final bool ok;
  final String note;
}

const _stoolSwatches = [
  _StoolSwatch(Color(0xFFF1EFE6), 'أبيض أو رمادي', false, 'ممكن علامة مشكلة في الكبد — كلّمي الطبيب النهارده.'),
  _StoolSwatch(Color(0xFFEDE3B8), 'أصفر باهت جداً', false, 'محتاج كشف النهارده، خصوصًا مع صفرا.'),
  _StoolSwatch(Color(0xFFE3B505), 'أصفر', true, 'طبيعي مع الرضاعة الطبيعية.'),
  _StoolSwatch(Color(0xFF6B8E23), 'أخضر', true, 'غالباً طبيعي.'),
  _StoolSwatch(Color(0xFF8B5A2B), 'بني', true, 'طبيعي.'),
  _StoolSwatch(Color(0xFF2B2B2B), 'أسود', false, 'طبيعي أول يومين بعد الولادة فقط — بعد كده محتاج كشف.'),
  _StoolSwatch(Color(0xFFB22222), 'أحمر / دم', false, 'محتاج طبيب. لو كمية كبيرة روحي الطوارئ.'),
];

class _StoolFlow extends StatefulWidget {
  const _StoolFlow({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_StoolFlow> createState() => _StoolFlowState();
}

class _StoolFlowState extends State<_StoolFlow> {
  _StoolSwatch? _picked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = _picked;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const _BotLine(text: 'اختاري اللون الأقرب لبراز طفلك:'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in _stoolSwatches)
              InkWell(
                onTap: () => setState(() => _picked = s),
                borderRadius: AppRadius.brMd,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: AppRadius.brMd,
                          border: Border.all(
                            color: identical(s, picked) ? AppColors.primary : AppColors.onSurface.withValues(alpha: 0.15),
                            width: identical(s, picked) ? 3 : 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(s.name, textAlign: TextAlign.center, maxLines: 2, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (picked != null) ...[
          const SizedBox(height: 14),
          _InfoCard(
            accent: picked.ok ? AppColors.tertiary : AppColors.error,
            child: Text(
              picked.note,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.45),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextButton(onPressed: widget.onDone, child: const Text('رجوع للشات')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Daily plan
// ---------------------------------------------------------------------------

class _PlanFlow extends ConsumerWidget {
  const _PlanFlow({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final babyName = ref.watch(prefsServiceProvider).getBabyName();
    final async = ref.watch(aiDailyPlanProvider);
    String t(String s) => withBabyName(s, babyName);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(aiDailyPlanProvider),
          child: const Text('حاولي تاني'),
        ),
      ),
      data: (result) {
        final plan = result.plan;
        if (plan == null) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BotLine(text: aiStatusText(result.status, result.detail)),
              const SizedBox(height: 12),
              FilledButton(
                style: _primaryButton(),
                onPressed: () => ref.invalidate(aiDailyPlanProvider),
                child: const Text('حاولي تاني'),
              ),
              TextButton(onPressed: onDone, child: const Text('رجوع')),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const _BotLine(text: 'خطة خفيفة ليومكوا:'),
            if (plan.tip.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoCard(
                accent: AppColors.secondary,
                child: Text(t(plan.tip), style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
              ),
            ],
            for (final a in plan.activities) ...[
              const SizedBox(height: 10),
              _InfoCard(
                accent: AppColors.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${t(a.title)} • ${a.minutes} دقايق',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (a.why.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(t(a.why), style: theme.textTheme.bodySmall),
                    ],
                    for (var i = 0; i < a.steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${i + 1}. ${t(a.steps[i])}'),
                      ),
                  ],
                ),
              ),
            ],
            if (plan.quranMoment.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoCard(
                accent: AppColors.tertiary,
                child: Text('لحظة قرآن: ${t(plan.quranMoment)}'),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(onPressed: onDone, child: const Text('رجوع للشات')),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Meal
// ---------------------------------------------------------------------------

const _commonAllergies = ['بيض', 'ألبان', 'قمح', 'سمك', 'فول سوداني', 'مكسرات', 'سمسم'];

class _MealFlow extends ConsumerStatefulWidget {
  const _MealFlow({required this.onDone, required this.onReady});

  final VoidCallback onDone;
  final ValueChanged<AiMealRequest> onReady;

  @override
  ConsumerState<_MealFlow> createState() => _MealFlowState();
}

class _MealFlowState extends ConsumerState<_MealFlow> {
  final _ingredients = TextEditingController();
  final _other = TextEditingController();
  final _allergies = <String>{};

  @override
  void dispose() {
    _ingredients.dispose();
    _other.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tooYoung = ref.watch(prefsServiceProvider).getBabyAgeRangeIndex() == 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const _BotLine(text: 'وجبة مناسبة لسنه — قوليلي إيه الموجود عندك.'),
        const SizedBox(height: 12),
        if (tooYoung) ...[
          _InfoCard(
            accent: AppColors.secondary,
            child: Text(
              'في السن ده الرضاعة كفاية. الأكل الصلب بيبدأ حوالي 6 شهور حسب منظمة الصحة العالمية.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(style: _primaryButton(), onPressed: widget.onDone, child: const Text('تمام')),
        ] else ...[
          TextField(
            controller: _ingredients,
            maxLength: 300,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'إيه الموجود في البيت؟',
              hintText: 'مثلاً: بطاطس، جزر، فراخ، رز',
            ),
          ),
          const SizedBox(height: 8),
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
            decoration: const InputDecoration(labelText: 'حساسية تانية (اختياري)'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: _primaryButton(),
            onPressed: () {
              final other = _other.text.split(RegExp('[،,]')).map((s) => s.trim()).where((s) => s.isNotEmpty);
              widget.onReady(AiMealRequest(
                ingredients: _ingredients.text.trim(),
                allergies: {..._allergies, ...other}.toList(),
              ));
            },
            child: const Text('اقترحي وجبة'),
          ),
          TextButton(onPressed: widget.onDone, child: const Text('رجوع')),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Child basics (birth + gender) inside chat
// ---------------------------------------------------------------------------

class _ChildBasicsForm extends ConsumerStatefulWidget {
  const _ChildBasicsForm({required this.child, required this.onSaved});

  final GrowthChild child;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ChildBasicsForm> createState() => _ChildBasicsFormState();
}

class _ChildBasicsFormState extends ConsumerState<_ChildBasicsForm> {
  late String? _gender = widget.child.gender;
  late DateTime? _birth = widget.child.birthDate;
  bool _saving = false;

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? now.subtract(const Duration(days: 90)),
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: 'تاريخ ميلاد ${widget.child.name}',
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _save() async {
    if (_gender == null || _birth == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(growthRepositoryProvider).saveChildBasics(
            widget.child.id,
            birthDate: _birth!,
            gender: _gender!,
          );
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _InfoCard(
      accent: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('كمّلي بيانات ${widget.child.name}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('النوع', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _ChoiceChip(label: 'ولد', selected: _gender == 'male', onTap: () => setState(() => _gender = 'male')),
              _ChoiceChip(label: 'بنت', selected: _gender == 'female', onTap: () => setState(() => _gender = 'female')),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickBirth,
            icon: Icon(Symbols.calendar_month, size: 18),
            label: Text(
              _birth == null
                  ? 'اختاري تاريخ الميلاد'
                  : '${_birth!.day}/${_birth!.month}/${_birth!.year}',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            style: _primaryButton(),
            onPressed: _saving || _gender == null || _birth == null ? null : _save,
            child: Text(_saving ? '...' : 'حفظ وكمل'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _BotLine extends StatelessWidget {
  const _BotLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.clayLift,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: AppShadows.clayLift,
      ),
      child: child,
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brFull,
        side: BorderSide(color: AppColors.primary.withValues(alpha: selected ? 0 : 0.2)),
      ),
      child: InkWell(
        borderRadius: AppRadius.brFull,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.onPrimary : AppColors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

ButtonStyle _primaryButton() => FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
    );
