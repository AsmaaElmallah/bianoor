import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/floating_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tertiary_button.dart';
import '../application/auth_session_provider.dart';
import '../domain/auth_exception.dart' show BayanourAuthException;
import '../../emotional/application/emotional_curriculum_provider.dart';
import '../../math/application/math_curriculum_provider.dart';
import '../../quran/application/quran_curriculum_provider.dart';
import '../../visual/application/visual_curriculum_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signup(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      ref.invalidate(mathCurriculumProvider);
      ref.invalidate(visualCurriculumProvider);
      ref.invalidate(emotionalCurriculumProvider);
      ref.invalidate(quranCurriculumProvider);
      if (mounted) context.go(AppRoutes.language);
    } on BayanourAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialSignup(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) context.go(AppRoutes.language);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(authRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    // Floating mascot
                    Center(
                      child: FloatingWidget(
                        amplitude: 8,
                        duration: const Duration(milliseconds: 3800),
                        child: Image.asset(
                          AppAssets.mascotCapLying,
                          height: 110,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Symbols.sentiment_very_satisfied,
                                color: AppColors.primary, size: 40, fill: 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'المربي اللطيف',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'خطوتكِ الأولى نحو تربية هادئة وملهمة',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppShadows.soft,
                      ),
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            label: 'الاسم الكامل',
                            hint: 'أدخل اسمكِ هنا',
                            icon: Symbols.person,
                            textInputAction: TextInputAction.next,
                            controller: _nameCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                          ),
                          const SizedBox(height: 2),
                          AppTextField(
                            label: 'البريد الإلكتروني',
                            hint: 'email@example.com',
                            icon: Symbols.mail,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            controller: _emailCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'البريد مطلوب';
                              }
                              if (!v.contains('@')) return 'بريد غير صالح';
                              return null;
                            },
                          ),
                          const SizedBox(height: 2),
                          AppTextField(
                            label: 'كلمة المرور',
                            hint: '••••••••',
                            icon: Symbols.lock,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            controller: _passwordCtrl,
                            suffixIcon: _obscurePassword ? Symbols.visibility : Symbols.visibility_off,
                            onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                              if (v.length < 6) return '6 أحرف على الأقل';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: _loading ? 'جارٍ الإنشاء...' : 'إنشاء حساب',
                            height: 58,
                            onPressed: _loading ? null : _submit,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: AppColors.outlineVariant, thickness: 0.8)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'أو التسجيل عبر',
                                  style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
                                ),
                              ),
                              const Expanded(child: Divider(color: AppColors.outlineVariant, thickness: 0.8)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _SocialCircle(
                                icon: Symbols.android,
                                onTap: _loading ? null : () => _socialSignup(() => repo.loginWithGoogle()),
                              ),
                              _SocialCircle(
                                icon: Symbols.phone_iphone,
                                onTap: _loading ? null : () => _socialSignup(() => repo.loginWithApple()),
                              ),
                              _SocialCircle(
                                icon: Symbols.public,
                                onTap: _loading ? null : () => _socialSignup(() => repo.loginWithFacebook()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('لديكِ حساب بالفعل؟', style: theme.textTheme.bodyMedium),
                        TertiaryButton(
                          label: 'تسجيل الدخول',
                          onPressed: () => context.go(AppRoutes.login),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialCircle extends StatelessWidget {
  const _SocialCircle({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: AppColors.onSurface, size: 22),
        ),
      ),
    );
  }
}
