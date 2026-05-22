import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
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
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
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
        ],
      ),
    );
  }
}

class _LanguageTile extends StatefulWidget {
  const _LanguageTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final LanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<_LanguageTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.isSelected;
    final bg = selected
        ? Color.lerp(widget.option.bgColor, Colors.white, 0.4)!
        : AppColors.surfaceContainerLowest;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 85)
            : const Duration(milliseconds: 250),
        curve: _pressed ? Curves.easeIn : Curves.elasticOut,
        transform: Matrix4.identity()
          ..translate(0.0, _pressed ? 3.0 : 0.0)
          ..scale(_pressed ? 0.95 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.outline.withValues(alpha: 0.35),
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: _pressed
              ? []
              : selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFFC8906A).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
        ),
        child: Stack(
          children: [
            if (selected)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Symbols.check,
                      color: Colors.white, size: 16, fill: 1),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: selected ? 68 : 60,
                  height: selected ? 68 : 60,
                  decoration: BoxDecoration(
                    color: widget.option.bgColor,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.option.flagEmoji,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(height: 1, fontSize: selected ? 34 : 30),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.option.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: selected ? AppColors.primary : AppColors.onSurface,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
