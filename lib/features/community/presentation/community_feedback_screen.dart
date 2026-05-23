import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_button.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';

enum CommunityFeedbackKind { complaint, suggestion }

class CommunityFeedbackScreen extends ConsumerStatefulWidget {
  const CommunityFeedbackScreen({super.key, required this.kind});

  final CommunityFeedbackKind kind;

  @override
  ConsumerState<CommunityFeedbackScreen> createState() =>
      _CommunityFeedbackScreenState();
}

class _CommunityFeedbackScreenState
    extends ConsumerState<CommunityFeedbackScreen> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;

  bool get _isComplaint => widget.kind == CommunityFeedbackKind.complaint;

  String get _title => _isComplaint ? 'الشكاوى' : 'الاقتراحات';

  String get _prefsKey =>
      _isComplaint ? 'community_complaints_log' : 'community_suggestions_log';

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final entry = {
      'at': DateTime.now().toIso8601String(),
      'subject': _subjectController.text.trim(),
      'body': _bodyController.text.trim(),
    };
    final prefs = ref.read(prefsServiceProvider);
    final existing = prefs.getJsonList(_prefsKey) ?? [];
    existing.insert(0, entry);
    await prefs.setJsonList(_prefsKey, existing.take(20).toList());

    if (!mounted) return;
    setState(() => _sending = false);
    _subjectController.clear();
    _bodyController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isComplaint
              ? 'شكراً — تم تسجيل شكواكِ وسنعود إليكِ قريباً.'
              : 'شكراً — اقتراحكِ محفوظ ويُراجع من الفريق.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: _title,
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  TactileClayCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isComplaint ? Symbols.feedback : Symbols.lightbulb,
                          color: _isComplaint ? AppColors.error : AppColors.secondary,
                          size: 28,
                          fill: 1,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isComplaint
                                ? 'صفّي المشكلة بوضوح — نرد خلال ٤٨ ساعة عمل.'
                                : 'اقتراحكِ يساعدنا نحسّن بيانور للأمهات والأطفال.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ClayField(
                    controller: _subjectController,
                    label: _isComplaint ? 'موضوع الشكوى' : 'عنوان الاقتراح',
                    hint: _isComplaint ? 'مثال: الصوت لا يعمل' : 'مثال: درس عن النوم',
                    maxLines: 1,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'أدخلي عنواناً' : null,
                  ),
                  const SizedBox(height: 12),
                  _ClayField(
                    controller: _bodyController,
                    label: 'التفاصيل',
                    hint: 'اكتبي هنا...',
                    maxLines: 6,
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'أدخلي ١٠ أحرف على الأقل'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  TactileClayButton(
                    label: _sending ? 'جاري الإرسال...' : 'إرسال',
                    icon: Symbols.send,
                    onPressed: _sending ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClayField extends StatelessWidget {
  const _ClayField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLines,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadius.brMd,
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.06),
                offset: const Offset(3, 3),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.85),
                offset: const Offset(-2, -2),
                blurRadius: 6,
              ),
            ],
          ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        textAlign: TextAlign.right,
        validator: validator,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextField.hintStyle(theme),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
        ),
      ],
    );
  }
}
