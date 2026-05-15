import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/constants/app_assets.dart';
import '../../../shared/widgets/editorial_card.dart';
import '../../../shared/widgets/primary_button.dart';

class _Rule {
  const _Rule({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;
}

const _rules = <_Rule>[
  _Rule(
    icon: Symbols.gavel,
    color: AppColors.primary,
    text:
        'التحلي بالأخلاق واحترام الجميع والالتزام الديني في الحوارات والآداب والذوقيات. ومن يخالف سيصله تنبيه أول وإذا تكرر سيتم حذف عضويته وإيقاف جميع صلاحيات المتجاوزين.',
  ),
  _Rule(
    icon: Symbols.lightbulb,
    color: AppColors.secondary,
    text: 'أي اقتراحات يوجد قسم خاص بها نحن نهتم باقتراحاتكم وآرائكم.',
  ),
  _Rule(
    icon: Symbols.support_agent,
    color: AppColors.tertiary,
    text:
        'على من يواجه أي مشكلات التوجه لقسم الشكاوى ونحن سنهتم بحلها بأسرع وقت ممكن بإذن الله.',
  ),
  _Rule(
    icon: Symbols.copyright,
    color: AppColors.error,
    text:
        'الحقوق مملوكة لصاحبة التطبيق د. أريج نبيل وأي تجاوز سيكون تحت المسائلة القانونية.',
  ),
];

class FamilyRulesScreen extends ConsumerStatefulWidget {
  const FamilyRulesScreen({super.key});

  @override
  ConsumerState<FamilyRulesScreen> createState() => _FamilyRulesScreenState();
}

class _FamilyRulesScreenState extends ConsumerState<FamilyRulesScreen> {
  bool _accepted = false;

  Future<void> _onContinue() async {
    await ref.read(prefsServiceProvider).setRulesAccepted(true);
    if (mounted) context.go(AppRoutes.subscription);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        toolbarHeight: 58,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              AppAssets.logoBaby,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Symbols.account_circle, color: AppColors.primary, size: 26, fill: 1),
            ),
          ),
          onPressed: () {},
        ),
        title: Text('أهلاً، سارة',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.notifications, color: AppColors.primary, fill: 1),
            onPressed: () {},
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.surfaceContainerHighest),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Symbols.favorite,
                    color: AppColors.onSecondaryContainer,
                    size: 34,
                    fill: 1,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'قوانين عائلة بيانور',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لضمان بيئة آمنة وداعمة لجميع أفراد عائلتنا.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),

              ..._rules.map(
                (rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EditorialCard(
                    accentColor: rule.color,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(rule.icon, color: rule.color, size: 24, fill: 1),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            rule.text,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.onSurface,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),
              Center(
                child: Text(
                  'نسأل الله لنا ولكم كل التوفيق والنجاح',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _accepted = !_accepted),
                      borderRadius: AppRadius.brMd,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _accepted,
                                onChanged: (v) => setState(() => _accepted = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'أقسم بالله العظيم أن ألتزم بهذه القوانين وأحترم خصوصية الجميع',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'أوافق وألتزم',
                      icon: Symbols.how_to_reg,
                      iconLeading: true,
                      height: 62,
                      onPressed: _accepted ? _onContinue : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
