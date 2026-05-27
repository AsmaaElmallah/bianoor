import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/community_providers.dart';
import '../domain/community_feedback_models.dart';

class CommunityFeedbackHistoryScreen extends ConsumerWidget {
  const CommunityFeedbackHistoryScreen({super.key, required this.kind});

  final CommunityFeedbackKind kind;

  bool get _isComplaint => kind == CommunityFeedbackKind.complaint;

  String get _title => _isComplaint ? 'شكوايَ السابقة' : 'اقتراحاتي السابقة';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).valueOrNull?.user;
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
            child: user == null
                ? _LoginPrompt(isComplaint: _isComplaint)
                : ref.watch(myCommunityFeedbackProvider(kind)).when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => _EmptyState(
                        message: 'تعذر تحميل الطلبات — حاولي لاحقاً.',
                        icon: Symbols.error,
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return _EmptyState(
                            message: _isComplaint
                                ? 'لم ترسلي شكاوى بعد — أو لم تُربط بحسابك.'
                                : 'لم ترسلي اقتراحات بعد — أو لم تُربط بحسابك.',
                            icon: _isComplaint ? Symbols.feedback : Symbols.lightbulb,
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(myCommunityFeedbackProvider(kind));
                            await ref.read(myCommunityFeedbackProvider(kind).future);
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _FeedbackTicketCard(
                                ticket: items[index],
                                theme: theme,
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.isComplaint});

  final bool isComplaint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: TactileClayCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.lock,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 12),
            Text(
              'سجّلي الدخول لمتابعة ${isComplaint ? 'شكاواكِ' : 'اقتراحاتكِ'} وردود الفريق.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.45,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.push(AppRoutes.login),
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackTicketCard extends StatelessWidget {
  const _FeedbackTicketCard({
    required this.ticket,
    required this.theme,
  });

  final CommunityFeedbackTicket ticket;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy • HH:mm', 'ar').format(ticket.createdAt);
    final statusColor = _statusColor(ticket.boardStatus);

    return TactileClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brSm,
                ),
                child: Text(
                  ticket.statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dateLabel,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ticket.body,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (ticket.hasAdminReply) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.45),
                borderRadius: AppRadius.brMd,
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Symbols.support_agent,
                        size: 18,
                        color: AppColors.secondary,
                        fill: 1,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'رد فريق بيانور',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket.adminReply!,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (ticket.boardStatus != 'closed') ...[
            const SizedBox(height: 10),
            Text(
              'نراجع طلبكِ — سنرد هنا عند الجاهزية.',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'replied':
        return AppColors.secondary;
      case 'in_review':
        return AppColors.tertiary;
      case 'closed':
        return AppColors.outline;
      case 'new':
      default:
        return AppColors.primary;
    }
  }
}
