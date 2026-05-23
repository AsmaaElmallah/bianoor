import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_button.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../community/presentation/community_feedback_screen.dart';
import '../../community/presentation/community_faq_screen.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';

class ConsultationsScreen extends StatelessWidget {
  const ConsultationsScreen({super.key, this.paidOnly = false});

  final bool paidOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = paidOnly
        ? 'استشارات مدفوعة'
        : 'استشارات سلوكية';

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
                        paidOnly
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
                if (!paidOnly) ...[
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
                  label: paidOnly ? 'حجز استشارة (قريباً)' : 'طلب استشارة مجانية',
                  icon: Symbols.calendar_month,
                  onPressed: paidOnly
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('الحجز المدفوع قيد التفعيل قريباً'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CommunityFeedbackScreen(
                                kind: CommunityFeedbackKind.complaint,
                              ),
                            ),
                          ),
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
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
