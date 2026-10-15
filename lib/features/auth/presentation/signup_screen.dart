import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../application/post_auth.dart';
import '../data/auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/user_model.dart';
import 'widgets/social_button.dart';

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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _goAfterAuth() async {
    await finishSignIn(ref);
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signup(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      TextInput.finishAutofillContext();
      await _goAfterAuth();
    } on EmailConfirmationRequired catch (e) {
      TextInput.finishAutofillContext();
      _showMessage(e.message);
      if (mounted) context.go(AppRoutes.login);
    } catch (e) {
      _showMessage(AuthFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialSignup(Future<UserModel> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      await _goAfterAuth();
    } catch (e) {
      _showMessage(AuthFailure.from(e).message);
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
                          duration: const Duration(milliseconds: 3800),
                          child: Image.asset(
                            AppAssets.mascotCapLying,
                            height: 110,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Symbols.sentiment_very_satisfied,
                              color: AppColors.primary,
                              size: 64,
                              fill: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'بيانور',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'أول خطوة لتربية هادية وملهمة',
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
                              label: 'اسمك',
                              hint: 'اكتبي اسمك هنا',
                              icon: Symbols.person,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              maxLength: 40,
                              controller: _nameCtrl,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'اكتبي اسمك'
                                  : null,
                            ),
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
                            const SizedBox(height: 2),
                            AppTextField(
                              label: 'كلمة السر',
                              hint: '6 حروف أو أرقام على الأقل',
                              icon: Symbols.lock,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              textDirection: TextDirection.ltr,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) => _submit(),
                              controller: _passwordCtrl,
                              suffixIcon: _obscurePassword
                                  ? Symbols.visibility
                                  : Symbols.visibility_off,
                              onSuffixTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'اكتبي كلمة السر';
                                if (v.length < 6) return '6 حروف أو أرقام على الأقل';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            PrimaryButton(
                              label: _loading ? 'لحظة...' : 'اعملي الحساب',
                              height: 58,
                              onPressed: _loading ? null : _submit,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: AppColors.outlineVariant, thickness: 0.8),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              label: 'التسجيل بحساب جوجل',
                              onTap: _loading
                                  ? null
                                  : () => _socialSignup(repo.loginWithGoogle),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('عندك حساب بالفعل؟', style: theme.textTheme.bodyMedium),
                          TertiaryButton(
                            label: 'سجّلي دخول',
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
          ),
        ],
      ),
    );
  }
}
