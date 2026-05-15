import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tertiary_button.dart';
import '../data/auth_repository.dart';
import 'widgets/social_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).login(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (mounted) context.go(AppRoutes.language);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialLogin(Future<void> Function() action) async {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A31332F),
                          blurRadius: 32,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Symbols.child_care,
                      color: AppColors.primary,
                      size: 46,
                      fill: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'بيانور',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'مرحباً بك مجدداً في رحلة التربية الواعية',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'example@email.com',
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
                const SizedBox(height: 6),
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
                    if (v.length < 4) return 'قصيرة جداً';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('تذكّرني', style: theme.textTheme.titleSmall),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          ),
                        ),
                      ],
                    ),
                    TertiaryButton(
                      label: 'نسيت كلمة المرور؟',
                      onPressed: () {},
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _loading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول',
                  icon: Symbols.login,
                  iconLeading: true,
                  height: 62,
                  onPressed: _loading ? null : _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.outlineVariant, thickness: 0.8)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'أو المتابعة باستخدام',
                        style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.outlineVariant, thickness: 0.8)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SocialButton(
                        label: 'جوجل',
                        icon: Symbols.android,
                        onTap: _loading ? null : () => _socialLogin(() => repo.loginWithGoogle()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SocialButton(
                        label: 'iOS أبل',
                        icon: Symbols.phone_iphone,
                        onTap: _loading ? null : () => _socialLogin(() => repo.loginWithApple()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ليس لديك حساب؟', style: theme.textTheme.titleMedium),
                    TertiaryButton(
                      label: 'إنشاء حساب جديد',
                      color: AppColors.primary,
                      onPressed: () => context.go(AppRoutes.signup),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Symbols.directions_car, color: AppColors.primary, size: 48, fill: 1),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
