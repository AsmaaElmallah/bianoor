import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_button.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../community/presentation/community_faq_screen.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../subscription/data/subscription_cloud_repository.dart';
import '../data/consultations_cloud_repository.dart';

class ConsultationsScreen extends ConsumerStatefulWidget {
  const ConsultationsScreen({super.key, this.paidOnly = false});

  final bool paidOnly;

  @override
  ConsumerState<ConsultationsScreen> createState() =>
      _ConsultationsScreenState();
}

class _ConsultationsScreenState extends ConsumerState<ConsultationsScreen> {
  bool get _paidOnly => widget.paidOnly;

  Future<void> _openRequestForm() async {
    if (_paidOnly) {
      final sub = await ref
          .read(subscriptionCloudRepositoryProvider)
          .fetchMySubscription();
      if (!mounted) return;
      if (sub?.isActive != true) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('اشتراك مطلوب'),
            content: const Text(
              'الاستشارات المدفوعة متاحة للمشتركين فقط.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.subscription);
                },
                child: const Text('الباقات'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final topicCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var sending = false;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
              title: const Text('طلب استشارة'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: topicCtrl,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'الموضوع',
                          hintText: 'مثال: صعوبة النوم',
                          hintStyle: AppTextField.hintStyle(Theme.of(ctx)),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'أدخلي موضوعاً' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: detailsCtrl,
                        textAlign: TextAlign.right,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'التفاصيل',
                          hintText: 'اكتبي باختصار...',
                          hintStyle: AppTextField.hintStyle(Theme.of(ctx)),
                        ),
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? 'أدخلي ١٠ أحرف على الأقل'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setLocal(() => sending = true);
                          final ok = await ref
                              .read(consultationsCloudRepositoryProvider)
                              .submitRequest(
                                topic: topicCtrl.text.trim(),
                                details: detailsCtrl.text.trim(),
                              );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx, ok);
                        },
                  child: Text(sending ? 'جاري الإرسال...' : 'إرسال'),
                ),
              ],
            );
          },
        );
      },
    );

    topicCtrl.dispose();
    detailsCtrl.dispose();

    if (!mounted || submitted == null) return;
    if (submitted == true) {
      ref.invalidate(myConsultationRequestsProvider);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          submitted
              ? 'تم إرسال طلب الاستشارة — سنعود إليكِ قريباً.'
              : 'تعذّر الإرسال — سجّلي الدخول وتأكدي من اتصال السحابة.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String _statusLabel(String? status) {
    switch (status) {
      case 'scheduled':
        return 'مجدول';
      case 'done':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغى';
      case 'new':
      default:
        return 'جديد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _paidOnly ? 'استشارات مدفوعة' : 'استشارات سلوكية';
    final myRequests = ref.watch(myConsultationRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: title,
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                TactileClayCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Symbols.support_agent,
                        size: 40,
                        color: AppColors.tertiary,
                        fill: 1,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _paidOnly
                            ? 'جلسات فردية مع مختصين معتمدين في التربية والسلوك.'
                            : 'إرشاد أولي للأمهات حول السلوك والنوم والتغذية.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!_paidOnly) ...[
                  _InfoRow(
                    icon: Symbols.schedule,
                    label: 'الرد خلال ٢٤–٤٨ ساعة',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Symbols.verified_user,
                    label: 'سرية تامة لمعلوماتك',
                  ),
                  const SizedBox(height: 20),
                ],
                TactileClayButton(
                  label: _paidOnly ? 'حجز استشارة مدفوعة' : 'طلب استشارة',
                  icon: Symbols.calendar_month,
                  onPressed: _openRequestForm,
                ),
                const SizedBox(height: 12),
                TactileClayButton(
                  label: 'أسئلة شائعة',
                  icon: Symbols.quiz,
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.onSecondaryContainer,
                  depthColor: AppColors.secondaryDim,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CommunityFaqScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'طلباتي',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                myRequests.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => Text(
                    'تعذّر تحميل الطلبات',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  data: (rows) {
                    if (rows.isEmpty) {
                      return Text(
                        'لا طلبات بعد — ابدئي بطلب استشارة.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final row in rows)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TactileClayCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          row['topic'] as String? ?? '—',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius: AppRadius.brFull,
                                        ),
                                        child: Text(
                                          _statusLabel(
                                            row['status'] as String?,
                                          ),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: AppColors.onPrimaryContainer,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((row['details'] as String?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      row['details'] as String,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if ((row['admin_note'] as String?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'ملاحظة: ${row['admin_note']}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22, fill: 1),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
