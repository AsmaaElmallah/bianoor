import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../community/presentation/widgets/club_shared.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/growth_providers.dart';
import '../data/growth_repository.dart';
import '../domain/growth_calc.dart';

/// «متتبع النمو» — WHO growth curves computed on-device; no AI needed for the math.
class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(growthDataProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: 'متتبع النمو', onBack: () => Navigator.of(context).pop()),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _Message(
                text: 'تعذّر تحميل بيانات النمو',
                action: 'حاولي تاني',
                onAction: () => ref.invalidate(growthDataProvider),
              ),
              data: (d) {
                final child = d.child;
                if (child == null) {
                  return const _Message(text: 'سجلي دخولك وكملي بيانات طفلك الأول عشان تتابعي نموه.');
                }
                if (!child.isReady) return _SetupForm(child: child);
                return _GrowthBody(child: child, measurements: d.measurements);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// First-time setup: birth date + gender (needed for the WHO curves)
// ---------------------------------------------------------------------------

class _SetupForm extends ConsumerStatefulWidget {
  const _SetupForm({required this.child});

  final GrowthChild child;

  @override
  ConsumerState<_SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends ConsumerState<_SetupForm> {
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
      await ref.read(growthRepositoryProvider).saveChildBasics(widget.child.id, birthDate: _birth!, gender: _gender!);
      ref.invalidate(growthDataProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showClubSnack(context, 'تعذّر الحفظ، حاولي تاني');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Symbols.monitoring, size: 56, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(
          'خطوة واحدة قبل ما نبدأ',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'منحنيات النمو بتختلف حسب العمر بالظبط ونوع الطفل، فمحتاجين نعرفهم مرة واحدة بس.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'male', label: Text('ولد'), icon: Icon(Symbols.boy)),
            ButtonSegment(value: 'female', label: Text('بنت'), icon: Icon(Symbols.girl)),
          ],
          selected: {if (_gender != null) _gender!},
          emptySelectionAllowed: true,
          onSelectionChanged: (s) => setState(() => _gender = s.isEmpty ? null : s.first),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickBirth,
          icon: const Icon(Symbols.cake),
          label: Text(_birth == null ? 'اختاري تاريخ الميلاد' : 'تاريخ الميلاد: ${_fmtDate(_birth!)}'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _gender == null || _birth == null || _saving ? null : _save,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _saving
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('ابدئي المتابعة'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Main view
// ---------------------------------------------------------------------------

class _GrowthBody extends ConsumerStatefulWidget {
  const _GrowthBody({required this.child, required this.measurements});

  final GrowthChild child;
  final List<GrowthMeasurement> measurements;

  @override
  ConsumerState<_GrowthBody> createState() => _GrowthBodyState();
}

class _GrowthBodyState extends ConsumerState<_GrowthBody> {
  GrowthMetric _metric = GrowthMetric.weight;

  GrowthChild get child => widget.child;

  double? _valueOf(GrowthMeasurement m, GrowthMetric metric) =>
      metric == GrowthMetric.weight ? m.weightKg : m.lengthCm;

  List<GrowthMeasurement> _with(GrowthMetric metric) => [
        for (final m in widget.measurements)
          if (_valueOf(m, metric) != null && ageInMonths(child.birthDate!, m.measuredOn) <= maxGrowthMonths) m,
      ];

  GrowthReading? _latestReading(GrowthMetric metric) {
    final list = _with(metric);
    if (list.isEmpty) return null;
    final m = list.last;
    return readGrowth(metric, child.isMale, ageInMonths(child.birthDate!, m.measuredOn), _valueOf(m, metric)!);
  }

  bool get _weightDropped {
    final list = _with(GrowthMetric.weight);
    if (list.length < 2) return false;
    double z(GrowthMeasurement m) =>
        growthZ(GrowthMetric.weight, child.isMale, ageInMonths(child.birthDate!, m.measuredOn), m.weightKg!);
    return droppedOffCurve(z(list[list.length - 2]), z(list.last));
  }

  String? get _projection {
    final list = _with(GrowthMetric.weight);
    if (list.isEmpty) return null;
    final m = list.last;
    final age = ageInMonths(child.birthDate!, m.measuredOn);
    if (age + 1 > maxGrowthMonths) return null;
    final z = growthZ(GrowthMetric.weight, child.isMale, age, m.weightKg!);
    final next = growthValueAtZ(GrowthMetric.weight, child.isMale, age + 1, z);
    return 'لو فضل ماشي على نفس منحناه، وزنه المتوقع بعد شهر من آخر قياس حوالي ${next.toStringAsFixed(1)} كجم.';
  }

  String _askQuestion() {
    final age = _ageText(child.birthDate!, DateTime.now());
    final w = _with(GrowthMetric.weight);
    final l = _with(GrowthMetric.length);
    final wr = _latestReading(GrowthMetric.weight);
    final lr = _latestReading(GrowthMetric.length);
    final parts = [
      '${child.isMale ? 'ابني' : 'بنتي'} عمره $age',
      if (w.isNotEmpty && wr != null)
        'وزنه ${w.last.weightKg!.toStringAsFixed(1)} كجم (المئين ${wr.percentile.round()} على منحنيات WHO)',
      if (l.isNotEmpty && lr != null) 'وطوله ${l.last.lengthCm!.toStringAsFixed(1)} سم (المئين ${lr.percentile.round()})',
    ];
    return '${parts.join('، ')}. نموه كده كويس؟ وإزاي أدعم نموه؟';
  }

  Future<void> _delete(GrowthMeasurement m) async {
    try {
      await ref.read(growthRepositoryProvider).deleteMeasurement(m.id);
      ref.invalidate(growthDataProvider);
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر الحذف');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final ageNow = ageInMonths(child.birthDate!, now);
    final weight = _latestReading(GrowthMetric.weight);
    final length = _latestReading(GrowthMetric.length);
    final projection = _projection;
    final points = [
      for (final m in _with(_metric)) Offset(ageInMonths(child.birthDate!, m.measuredOn), _valueOf(m, _metric)!),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${child.name} — عمره ${_ageText(child.birthDate!, now)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (weight == null && length == null)
                Text(
                  'سجلي أول قياس للوزن أو الطول، وهنوريكي مكانه على منحنى منظمة الصحة العالمية.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              if (weight != null) _ReadingRow(icon: Symbols.monitor_weight, reading: weight),
              if (length != null) _ReadingRow(icon: Symbols.height, reading: length),
              if (_weightDropped)
                const _ReadingRow(
                  icon: Symbols.trending_down,
                  reading: GrowthReading(
                    z: 0,
                    percentile: -1,
                    level: GrowthLevel.watch,
                    label: 'الوزن نزل عن منحناه من آخر قياس — يستاهل متابعة مع الطبيب',
                  ),
                ),
              if (projection != null) ...[
                const SizedBox(height: 4),
                Text(projection, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (ageNow > maxGrowthMonths)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'المتتبع بيغطي من الولادة لحد سنتين.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        SegmentedButton<GrowthMetric>(
          segments: const [
            ButtonSegment(value: GrowthMetric.weight, label: Text('الوزن'), icon: Icon(Symbols.monitor_weight)),
            ButtonSegment(value: GrowthMetric.length, label: Text('الطول'), icon: Icon(Symbols.height)),
          ],
          selected: {_metric},
          onSelectionChanged: (s) => setState(() => _metric = s.first),
        ),
        const SizedBox(height: 12),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: CustomPaint(
                  painter: _GrowthChartPainter(
                    metric: _metric,
                    male: child.isMale,
                    points: points,
                    maxMonths: math.min(maxGrowthMonths, math.max(6, (ageNow + 2).ceilToDouble())),
                    textStyle: theme.textTheme.labelSmall!.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الخط الغامق = متوسط الأطفال في نفس السن. المساحة الخضرا = المدى الطبيعي (من 3% لـ 97%). '
                'المهم إن ${child.isMale ? 'ابنك' : 'بنتك'} ماشي على منحنى ثابت.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _showAddSheet(context, child),
          icon: const Icon(Symbols.add),
          label: const Text('سجلي قياس جديد'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        if (weight != null || length != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('${AppRoutes.aiAssistant}?q=${Uri.encodeComponent(_askQuestion())}'),
            icon: const Icon(Symbols.chat),
            label: const Text('اسألي مساعدة بيانور عن نموه'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
        if (widget.measurements.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('القياسات', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final m in widget.measurements.reversed)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: AppColors.surfaceContainerLowest,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              child: ListTile(
                title: Text(_fmtDate(m.measuredOn)),
                subtitle: Text([
                  'عمره ${_ageText(child.birthDate!, m.measuredOn)}',
                  if (m.weightKg != null) '${m.weightKg!.toStringAsFixed(2)} كجم',
                  if (m.lengthCm != null) '${m.lengthCm!.toStringAsFixed(1)} سم',
                ].join(' • ')),
                trailing: IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Symbols.delete, color: AppColors.onSurfaceVariant),
                  onPressed: () => _delete(m),
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'الحسبة على منحنيات نمو منظمة الصحة العالمية (WHO Child Growth Standards). ده للمتابعة ومش تشخيص — '
          'طبيب الأطفال هو اللي يقيّم النمو.',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.brLg,
        boxShadow: [
          BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.icon, required this.reading});

  final IconData icon;
  final GrowthReading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watch = reading.level == GrowthLevel.watch;
    final color = watch ? AppColors.error : AppColors.tertiaryDim;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(watch ? Symbols.error : icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reading.label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (reading.percentile >= 0)
                  Text(
                    'أكبر من حوالي ${reading.percentile.round().clamp(1, 99)}% من الأطفال في نفس سنه',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add measurement
// ---------------------------------------------------------------------------

Future<void> _showAddSheet(BuildContext context, GrowthChild child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _AddMeasurementSheet(child: child),
  );
}

class _AddMeasurementSheet extends ConsumerStatefulWidget {
  const _AddMeasurementSheet({required this.child});

  final GrowthChild child;

  @override
  ConsumerState<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends ConsumerState<_AddMeasurementSheet> {
  final _weight = TextEditingController();
  final _length = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _weight.dispose();
    _length.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    var t = c.text.trim().replaceAll('٫', '.').replaceAll(',', '.');
    for (var i = 0; i < 10; i++) {
      t = t.replaceAll(arabicDigits[i], '$i');
    }
    return t.isEmpty ? null : double.tryParse(t);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.child.birthDate!,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String? _validate(double? w, double? l) {
    if (w == null && l == null) return 'اكتبي الوزن أو الطول';
    if (w != null && (w < 1 || w > 30)) return 'الوزن لازم يكون بالكيلو (مثلاً 6.5)';
    if (l != null && (l < 35 || l > 120)) return 'الطول لازم يكون بالسنتي (مثلاً 64)';
    final age = ageInMonths(widget.child.birthDate!, _date);
    final male = widget.child.isMale;
    if (age <= maxGrowthMonths) {
      if (w != null && growthZ(GrowthMetric.weight, male, age, w).abs() > 6) {
        return 'الوزن ده بعيد جداً عن المعتاد لسنه — اتأكدي من الرقم';
      }
      if (l != null && growthZ(GrowthMetric.length, male, age, l).abs() > 6) {
        return 'الطول ده بعيد جداً عن المعتاد لسنه — اتأكدي من الرقم';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final w = _parse(_weight);
    final l = _parse(_length);
    final error = _validate(w, l);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref
          .read(growthRepositoryProvider)
          .saveMeasurement(widget.child.id, measuredOn: _date, weightKg: w, lengthCm: l);
      ref.invalidate(growthDataProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'تعذّر الحفظ، حاولي تاني';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numbers = [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,٫]'))];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('قياس جديد', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Symbols.calendar_month),
            label: Text('يوم القياس: ${_fmtDate(_date)}'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: numbers,
            decoration: const InputDecoration(labelText: 'الوزن (كجم)', hintText: 'مثلاً 6.5', suffixText: 'كجم'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _length,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: numbers,
            decoration: const InputDecoration(labelText: 'الطول (سم) — اختياري', hintText: 'مثلاً 64', suffixText: 'سم'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _saving
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chart
// ---------------------------------------------------------------------------

class _GrowthChartPainter extends CustomPainter {
  _GrowthChartPainter({
    required this.metric,
    required this.male,
    required this.points,
    required this.maxMonths,
    required this.textStyle,
  });

  final GrowthMetric metric;
  final bool male;
  final List<Offset> points;
  final double maxMonths;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0, bottom = 22.0, top = 8.0, right = 8.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;

    double v(double months, double z) => growthValueAtZ(metric, male, months, z);
    var minY = v(0, growthChartZ.first);
    var maxY = v(maxMonths, growthChartZ.last);
    for (final p in points) {
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    final pad = (maxY - minY) * 0.05;
    minY = (minY - pad).floorToDouble();
    maxY = (maxY + pad).ceilToDouble();

    Offset at(double months, double value) =>
        Offset(left + w * (months / maxMonths), top + h * (1 - (value - minY) / (maxY - minY)));

    // Grid + labels.
    final grid = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    final yStep = _niceStep((maxY - minY) / 5);
    for (var y = (minY / yStep).ceil() * yStep; y <= maxY; y += yStep) {
      final p = at(0, y);
      canvas.drawLine(Offset(left, p.dy), Offset(left + w, p.dy), grid);
      _label(canvas, y.toStringAsFixed(yStep < 1 ? 1 : 0), Offset(2, p.dy - 7));
    }
    final xStep = maxMonths <= 12 ? 2 : 3;
    for (var m = 0; m <= maxMonths; m += xStep) {
      final p = at(m.toDouble(), minY);
      canvas.drawLine(Offset(p.dx, top), Offset(p.dx, top + h), grid);
      _label(canvas, '$m', Offset(p.dx - 4, top + h + 4));
    }

    // Normal band (3rd–97th) + percentile lines.
    const steps = 48;
    final band = Path();
    for (var i = 0; i <= steps; i++) {
      final m = maxMonths * i / steps;
      final p = at(m, v(m, growthChartZ.last));
      i == 0 ? band.moveTo(p.dx, p.dy) : band.lineTo(p.dx, p.dy);
    }
    for (var i = steps; i >= 0; i--) {
      final m = maxMonths * i / steps;
      final p = at(m, v(m, growthChartZ.first));
      band.lineTo(p.dx, p.dy);
    }
    band.close();
    canvas.drawPath(band, Paint()..color = AppColors.tertiary.withValues(alpha: 0.12));

    for (final z in growthChartZ) {
      final line = Path();
      for (var i = 0; i <= steps; i++) {
        final m = maxMonths * i / steps;
        final p = at(m, v(m, z));
        i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = z == 0 ? 2 : 1
          ..color = AppColors.tertiaryDim.withValues(alpha: z == 0 ? 0.8 : 0.35),
      );
    }

    // Child's measurements.
    final visible = [for (final p in points) if (p.dx <= maxMonths) p];
    if (visible.length > 1) {
      final path = Path()..moveTo(at(visible.first.dx, visible.first.dy).dx, at(visible.first.dx, visible.first.dy).dy);
      for (final p in visible.skip(1)) {
        final o = at(p.dx, p.dy);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.primary,
      );
    }
    for (final p in visible) {
      final o = at(p.dx, p.dy);
      canvas.drawCircle(o, 5, Paint()..color = AppColors.surfaceContainerLowest);
      canvas.drawCircle(o, 4, Paint()..color = AppColors.primary);
    }
  }

  void _label(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(text: TextSpan(text: text, style: textStyle), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, offset);
  }

  double _niceStep(double raw) {
    for (final s in [0.5, 1.0, 2.0, 5.0, 10.0]) {
      if (raw <= s) return s;
    }
    return 20;
  }

  @override
  bool shouldRepaint(_GrowthChartPainter old) =>
      old.metric != metric || old.points != points || old.maxMonths != maxMonths || old.male != male;
}

// ---------------------------------------------------------------------------

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _ageText(DateTime birth, DateTime on) {
  var months = (on.year - birth.year) * 12 + on.month - birth.month;
  if (on.day < birth.day) months--;
  if (months < 0) return 'أقل من يوم';
  final anchor = DateTime(birth.year, birth.month + months, birth.day);
  final days = DateTime(on.year, on.month, on.day).difference(anchor).inDays;
  if (months == 0) return days == 1 ? 'يوم واحد' : '$days يوم';
  final m = switch (months) {
    1 => 'شهر',
    2 => 'شهرين',
    <= 10 => '$months شهور',
    _ => '$months شهر',
  };
  return days > 0 ? '$m و$days يوم' : m;
}
