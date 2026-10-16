import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/auth_session_provider.dart';
import '../data/auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../../../shared/widgets/icon_3d.dart';
import '../../home/application/home_avatar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _editName(String? current) async {
    final ctrl = TextEditingController(text: current ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اسمك'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'مثلاً: أم سهيلة'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.trim().isEmpty || name.trim() == current) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).updateDisplayName(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اتحفظ الاسم')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is AuthFailure ? e.message : 'تعذّر حفظ الاسم';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickHomePhoto() async {
    setState(() => _busy = true);
    try {
      final saved = await pickHomeAvatar(ref);
      if (!mounted || !saved) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اتحفظت الصورة')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الصور')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetHomePhoto() async {
    setState(() => _busy = true);
    try {
      await clearHomeAvatar(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رجّعنا صورة بيانور')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).logout();
      await ref.read(prefsServiceProvider).setAuthenticated(false);
      if (mounted) context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AuthFailure ? e.message : 'تعذّر تسجيل الخروج';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب؟'),
        content: const Text(
          'سيتم حذف حسابكِ وبياناتكِ المرتبطة نهائيًا. لا يمكن التراجع.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      final prefs = ref.read(prefsServiceProvider);
      await prefs.setAuthenticated(false);
      await prefs.setOnboardingComplete(false);
      if (mounted) context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AuthFailure ? e.message : 'تعذّر حذف الحساب';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider).valueOrNull;
    final version = ref.watch(_appVersionProvider).valueOrNull;
    final hasHomePhoto = ref.watch(homeAvatarPathProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'الإعدادات',
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: AppRadius.brLg,
                    boxShadow: AppShadows.clayLift,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? const Icon(Symbols.person, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'مستخدمة بيانور',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (user?.email.isNotEmpty == true)
                              Text(
                                user!.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SettingsTile(
                  icon: Symbols.add_a_photo,
                  title: 'تغيير صورة الرئيسية',
                  onTap: _busy ? null : _pickHomePhoto,
                ),
                if (hasHomePhoto)
                  _SettingsTile(
                    icon: Symbols.restart_alt,
                    title: 'إرجاع صورة بيانور',
                    onTap: _busy ? null : _resetHomePhoto,
                  ),
                _SettingsTile(
                  icon: Symbols.edit,
                  title: user?.displayName == null ? 'اكتبي اسمك' : 'تعديل الاسم',
                  onTap: _busy || user == null
                      ? null
                      : () => _editName(user.displayName),
                ),
                _SettingsTile(
                  icon: Symbols.workspace_premium,
                  title: 'الاشتراك',
                  onTap: _busy
                      ? null
                      : () => context.push(AppRoutes.subscription),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _busy ? 'جارٍ…' : 'تسجيل الخروج',
                  onPressed: _busy ? null : _logout,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _deleteAccount,
                  child: Text(
                    'حذف الحساب نهائيًا',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (version != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'بيانور • الإصدار $version',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon3D(art: null, icon: icon, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Icon(Icons.chevron_left, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
