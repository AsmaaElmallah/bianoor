import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/theme/app_colors.dart';
import '../../curriculum/data/progress_sync_service.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/floating_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tertiary_button.dart';
import '../data/auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/user_model.dart';

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

  Future<void> _goAfterAuth() async {
    try {
      await ref.read(progressSyncServiceProvider).pullAndMerge();
    } catch (_) {}
    if (!mounted) return;
    final prefs = ref.read(prefsServiceProvider);
    final hasBaby = prefs.getBabyName()?.trim().isNotEmpty ?? false;
    context.go(
      prefs.isOnboardingComplete() && hasBaby
          ? AppRoutes.home
          : AppRoutes.language,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).login(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (mounted) await _goAfterAuth();
    } on AuthFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthFailure.from(e).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخلي بريدك الإلكتروني أولاً')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(email: email);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('راجعي بريدك'),
          content: Text(
            'أرسلنا رابط إعادة تعيين كلمة المرور إلى:\n$email\n\n'
            'افتحي الرابط من الموبايل عشان ترجعي للتطبيق وتختاري كلمة مرور جديدة.\n'
            'لو مش ظاهر، شيكي مجلد Spam.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } on AuthFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthFailure.from(e).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialLogin(Future<UserModel> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) await _goAfterAuth();
    } on AuthFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthFailure.from(e).message)),
        );
      }
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
                    Center(
                      child: FloatingWidget(
                        amplitude: 8,
                        duration: const Duration(milliseconds: 3600),
                        child: Image.asset(
                          AppAssets.mascotCapLying,
                          height: 110,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(24),
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
                    if (!SupabaseBootstrap.isEnabled) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'السحابة غير مفعّلة — شغّلي:\nflutter run --dart-define-from-file=dart_defines.json',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                      suffixIcon: _obscurePassword
                          ? Symbols.visibility
                          : Symbols.visibility_off,
                      onSuffixTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'كلمة المرور مطلوبة';
                        }
                        if (v.length < 4) return 'قصيرة جداً';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'تذكّرني',
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) => setState(
                                    () => _rememberMe = v ?? false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TertiaryButton(
                              label: 'نسيت كلمة المرور؟',
                              onPressed: _loading ? null : _resetPassword,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label:
                          _loading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول',
                      icon: Symbols.login,
                      iconLeading: true,
                      height: 62,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: AppColors.outlineVariant,
                            thickness: 0.8,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'أو المتابعة باستخدام',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: AppColors.outlineVariant,
                            thickness: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _LoginSocialCircle(
                          icon: Symbols.android,
                          onTap: _loading
                              ? null
                              : () => _socialLogin(
                                    () => repo.loginWithGoogle(),
                                  ),
                        ),
                        _LoginSocialCircle(
                          icon: Symbols.phone_iphone,
                          onTap: _loading
                              ? null
                              : () => _socialLogin(
                                    () => repo.loginWithApple(),
                                  ),
                        ),
                        _LoginSocialCircle(
                          icon: Symbols.public,
                          onTap: _loading
                              ? null
                              : () => _socialLogin(
                                    () => repo.loginWithFacebook(),
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'ليس لديك حساب؟',
                          style: theme.textTheme.titleMedium,
                        ),
                        TertiaryButton(
                          label: 'إنشاء حساب جديد',
                          color: AppColors.primary,
                          onPressed: () => context.go(AppRoutes.signup),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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

class _LoginSocialCircle extends StatelessWidget {
  const _LoginSocialCircle({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
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
