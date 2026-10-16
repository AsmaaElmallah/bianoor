import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/supabase/supabase_bootstrap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../application/timeline_providers.dart';
import '../timeline_screen.dart';

/// Home: the one skill/feeding milestone due around now.
class TimelineHomeCard extends ConsumerWidget {
  const TimelineHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseBootstrap.isEnabled) return const SizedBox.shrink();
    final data = ref.watch(timelineDataProvider).valueOrNull;
    final item = data?.highlight;
    if (data == null || item == null) return const SizedBox.shrink();
    final (icon, color, label) = timelineKindStyle(item.kind);
    final theme = Theme.of(context);
    final when = timelineWhen(item.ageDays, data.ageDays!);

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: () => context.push(AppRoutes.timeline),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$label • $when', style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
