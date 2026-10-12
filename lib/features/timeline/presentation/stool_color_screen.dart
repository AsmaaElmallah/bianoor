import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../ai/data/ai_models.dart';
import '../../ai/presentation/widgets/ai_shared.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';

enum _Verdict { normal, doctorToday, urgent }

class _Swatch {
  const _Swatch(this.color, this.name, this.verdict, this.note);

  final Color color;
  final String name;
  final _Verdict verdict;
  final String note;
}

// Based on the infant stool colour card idea (pale stools = possible liver problem) and NHS guidance.
const _swatches = [
  _Swatch(Color(0xFFF1EFE6), 'أبيض أو رمادي فاتح', _Verdict.urgent,
      'البراز الأبيض أو الرمادي أو الطباشيري ممكن يكون علامة مشكلة في الكبد أو المرارة. لازم تكلمي الطبيب النهارده، خصوصاً لو فيه صفرا.'),
  _Swatch(Color(0xFFEDE3B8), 'أصفر باهت جداً', _Verdict.urgent,
      'اللون الباهت جداً (زي الطباشير أو الطين الفاتح) محتاج كشف النهارده، خصوصاً مع صفرا أو بول غامق.'),
  _Swatch(Color(0xFFE3B505), 'أصفر', _Verdict.normal, 'طبيعي — ده الشكل المعتاد للرضاعة الطبيعية، وممكن يكون طري وفيه حبيبات.'),
  _Swatch(Color(0xFFB59A1E), 'أصفر مخضر أو خردلي', _Verdict.normal, 'طبيعي.'),
  _Swatch(Color(0xFF6B8E23), 'أخضر', _Verdict.normal, 'غالباً طبيعي، خصوصاً مع اللبن الصناعي أو بعض الأكلات أو مكملات الحديد.'),
  _Swatch(Color(0xFF8B5A2B), 'بني', _Verdict.normal, 'طبيعي — خصوصاً مع اللبن الصناعي أو بعد بداية الأكل.'),
  _Swatch(Color(0xFF2B2B2B), 'أسود', _Verdict.doctorToday,
      'طبيعي في أول يومين بعد الولادة (العقي). بعد كده البراز الأسود محتاج كشف — إلا لو الطفل بياخد حديد والطبيب قالك إن ده متوقع.'),
  _Swatch(Color(0xFFB22222), 'أحمر أو فيه دم', _Verdict.doctorToday,
      'الدم في البراز محتاج طبيب. لو كمية كبيرة أو الطفل تعبان أو عنده حرارة أو بيرجّع، روحي الطوارئ.'),
];

class StoolColorScreen extends StatefulWidget {
  const StoolColorScreen({super.key});

  @override
  State<StoolColorScreen> createState() => _StoolColorScreenState();
}

class _StoolColorScreenState extends State<StoolColorScreen> {
  _Swatch? _picked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = _picked;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: 'كارت ألوان البراز', onBack: () => Navigator.of(context).pop()),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  'اختاري اللون الأقرب لبراز طفلك (في ضوء النهار لو تقدري):',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                  children: [
                    for (final s in _swatches)
                      InkWell(
                        borderRadius: AppRadius.brMd,
                        onTap: () => setState(() => _picked = s),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: s.color,
                                  borderRadius: AppRadius.brMd,
                                  border: Border.all(
                                    color: identical(s, picked) ? AppColors.primary : AppColors.outline,
                                    width: identical(s, picked) ? 3 : 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (picked != null) _VerdictCard(swatch: picked),
                const SizedBox(height: 16),
                Text(
                  'الكارت ده للتنبيه بس ومش تشخيص. لو قلقانة على أي لون أو شكل، كلمي الطبيب.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                const AiSourcesRow(sources: [
                  AiSource(
                    title: 'NHS — Baby poo',
                    url: 'https://www.nhs.uk/baby/caring-for-a-newborn/what-should-my-babys-poo-look-like/',
                  ),
                  AiSource(title: 'NHS — Newborn jaundice', url: 'https://www.nhs.uk/conditions/jaundice-newborn/'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.swatch});

  final _Swatch swatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg, icon, title) = switch (swatch.verdict) {
      _Verdict.normal => (AppColors.trackExerciseLight, AppColors.onSurface, Symbols.check_circle, 'غالباً طبيعي'),
      _Verdict.doctorToday => (AppColors.secondaryContainer, AppColors.onSurface, Symbols.stethoscope, 'محتاج طبيب'),
      _Verdict.urgent => (AppColors.errorDim, AppColors.onError, Symbols.emergency, 'كلمي الطبيب النهارده'),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(swatch.note, style: theme.textTheme.bodyMedium?.copyWith(color: fg, height: 1.6)),
        ],
      ),
    );
  }
}
