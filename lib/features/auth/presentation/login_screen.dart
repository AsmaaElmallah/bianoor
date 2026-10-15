import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/floating_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tertiary_button.dart';
import '../application/post_auth.dart';
import '../data/auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/user_model.dart';
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
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AuthFailure.from(e).message)),
    );
  }

  Future<void> _goAfterAuth() async {
    await finishSignIn(ref);
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).login(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      TextInput.finishAutofillContext();
      await _goAfterAuth();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(initialEmail: _emailCtrl.text.trim()),
    );
    if (email == null || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(email: email);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('شوفي إيميلك'),
          content: Text(
            'بعتنالك رابط تغيير كلمة السر على:\n$email\n\n'
            'افتحي الرابط من الموبايل ده، وهيرجعك للتطبيق تختاري كلمة سر جديدة.\n'
            'لو مش لاقياه، دوري في الـ Spam.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('تمام'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialLogin(Future<UserModel> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      await _goAfterAuth();
    } catch (e) {
      _showError(e);
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
                child: AutofillGroup(
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
                            errorBuilder: (_, __, ___) => const Icon(
                              Symbols.child_care,
                              color: AppColors.primary,
                              size: 64,
                              fill: 1,
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
                        'أهلاً بيكي تاني في رحلة التربية الواعية',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (kDebugMode && !SupabaseBootstrap.isEnabled) ...[
                        const SizedBox(height: 12),
                        Text(
                          'DEV: run with --dart-define-from-file=dart_defines.json',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      AppTextField(
                        label: 'الإيميل',
                        hint: 'example@email.com',
                        icon: Symbols.mail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        textDirection: TextDirection.ltr,
                        autofillHints: const [AutofillHints.email],
                        controller: _emailCtrl,
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        label: 'كلمة السر',
                        hint: '••••••••',
                        icon: Symbols.lock,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        textDirection: TextDirection.ltr,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        controller: _passwordCtrl,
                        suffixIcon: _obscurePassword
                            ? Symbols.visibility
                            : Symbols.visibility_off,
                        onSuffixTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'اكتبي كلمة السر' : null,
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TertiaryButton(
                          label: 'نسيتي كلمة السر؟',
                          onPressed: _loading ? null : _resetPassword,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: _loading ? 'لحظة...' : 'دخول',
                        icon: Symbols.login,
                        iconLeading: true,
                        height: 62,
                        onPressed: _loading ? null : _submit,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: AppColors.outlineVariant, thickness: 0.8),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'أو',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppColors.outlineVariant, thickness: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GoogleSignInButton(
                        label: 'الدخول بحساب جوجل',
                        onTap: _loading
                            ? null
                            : () => _socialLogin(repo.loginWithGoogle),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('معندكيش حساب؟', style: theme.textTheme.titleMedium),
                          TertiaryButton(
                            label: 'اعملي حساب جديد',
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
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _ctrl = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('نسيتي كلمة السر؟'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('اكتبي إيميلك، وهنبعتلك رابط تختاري بيه كلمة سر جديدة.'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ctrl,
              autofocus: widget.initialEmail.isEmpty,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.send,
              onFieldSubmitted: (_) => _send(),
              decoration: const InputDecoration(hintText: 'example@email.com'),
              validator: validateEmail,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _send, child: const Text('ابعتي الرابط')),
      ],
    );
  }
}
