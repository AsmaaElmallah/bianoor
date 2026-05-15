import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/primary_button.dart';
import '../domain/language_model.dart';

const _languages = <LanguageOption>[
  LanguageOption(code: 'en', name: 'English', flagEmoji: '🇬🇧', bgColor: AppColors.langEnglishBg),
  LanguageOption(code: 'ar', name: 'العربية', flagEmoji: '🇸🇦', bgColor: AppColors.langArabicBg),
  LanguageOption(code: 'fr', name: 'Français', flagEmoji: '🇫🇷', bgColor: AppColors.langFrenchBg),
  LanguageOption(code: 'de', name: 'Deutsch', flagEmoji: '🇩🇪', bgColor: AppColors.langGermanBg),
  LanguageOption(code: 'es', name: 'Español', flagEmoji: '🇪🇸', bgColor: AppColors.langSpanishBg),
  LanguageOption(code: 'tr', name: 'Türkçe', flagEmoji: '🇹🇷', bgColor: AppColors.langTurkishBg),
  LanguageOption(code: 'ur', name: 'اردو', flagEmoji: '🇵🇰', bgColor: AppColors.langUrduBg),
  LanguageOption(code: 'id', name: 'Indonesia', flagEmoji: '🇮🇩', bgColor: AppColors.langIndonesianBg),
];

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _selectedCode = 'ar';

  @override
  void initState() {
    super.initState();
    final saved = ref.read(prefsServiceProvider).getLanguage();
    if (saved != null) _selectedCode = saved;
  }

  Future<void> _onContinue() async {
    await ref.read(prefsServiceProvider).setLanguage(_selectedCode);
    if (mounted) context.go(AppRoutes.rules);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                'اختر لغتك المفضلة',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'الرجاء اختيار اللغة التي تفضل استخدام التطبيق بها',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: GridView.builder(
                    itemCount: _languages.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.98,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final lang = _languages[index];
                      final isSelected = lang.code == _selectedCode;
                      return _LanguageTile(
                        option: lang,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedCode = lang.code),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),
              PrimaryButton(
                label: 'متابعة',
                icon: Symbols.arrow_back,
                height: 58,
                onPressed: _onContinue,
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final LanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: AppRadius.brSm,
      child: InkWell(
        borderRadius: AppRadius.brSm,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2.2,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0F31332F),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              if (isSelected)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Symbols.check_circle,
                      color: AppColors.primary,
                      size: 18,
                      fill: 1,
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: option.bgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option.flagEmoji,
                      style: theme.textTheme.headlineMedium?.copyWith(height: 1),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    option.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
