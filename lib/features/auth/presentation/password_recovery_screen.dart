import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tertiary_button.dart';
import '../application/auth_session_provider.dart';
import '../data/auth_repository.dart';
import '../data/supabase_auth_repository.dart';

class PasswordRecoveryScreen extends ConsumerStatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  ConsumerState<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends ConsumerState<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _clearRecoveryAndLeave() async {
    ref.read(passwordRecoveryPendingProvider.notifier).state = false;
    await ref.read(prefsServiceProvider).setPasswordRecoveryPending(false);
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {}
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(
            newPassword: _passwordCtrl.text,
          );
      ref.read(passwordRecoveryPendingProvider.notifier).state = false;
      await ref.read(prefsServiceProvider).setPasswordRecoveryPending(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث كلمة المرور — سجّلي الدخول.')),
      );
      await ref.read(authRepositoryProvider).logout();
      if (mounted) context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AuthFailure ? e.message : 'تعذّر تحديث كلمة المرور.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'كلمة مرور جديدة',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختاري كلمة مرور قوية لحسابكِ',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _passwordCtrl,
                      label: 'كلمة المرور الجديدة',
                      hint: '••••••••',
                      icon: Symbols.lock,
                      obscureText: _obscure,
                      suffixIcon: _obscure
                          ? Symbols.visibility
                          : Symbols.visibility_off,
                      onSuffixTap: () => setState(() => _obscure = !_obscure),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return '6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirmCtrl,
                      label: 'تأكيد كلمة المرور',
                      hint: '••••••••',
                      icon: Symbols.lock,
                      obscureText: _obscure,
                      validator: (v) {
                        if (v != _passwordCtrl.text) {
                          return 'كلمتا المرور غير متطابقتين';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: _loading ? 'جاري الحفظ…' : 'حفظ كلمة المرور',
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 12),
                    TertiaryButton(
                      label: 'إلغاء والعودة لتسجيل الدخول',
                      onPressed: _loading ? null : _clearRecoveryAndLeave,
                    ),
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
