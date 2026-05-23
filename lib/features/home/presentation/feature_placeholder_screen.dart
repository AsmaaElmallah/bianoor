import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../domain/home_menu_data.dart';
import '../domain/home_menu_item.dart';
import 'home_navigation.dart';
import 'widgets/home_list_panel.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({super.key, required this.featureId});

  final String featureId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = homeMenuItemById(featureId);
    final title = item?.title ?? featureId;
    final children = item?.children ?? const <HomeMenuItem>[];

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
            child: children.isNotEmpty
                ? _ChildrenList(children: children)
                : _ComingSoon(title: title),
          ),
        ],
      ),
    );
  }
}

class _ChildrenList extends StatelessWidget {
  const _ChildrenList({required this.children});

  final List<HomeMenuItem> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        HomeListPanel(
          items: children,
          onItemTap: (item) => openHomeMenuItem(context, item),
        ),
      ],
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: AppShadows.clayLift,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Symbols.construction, color: AppColors.primary, size: 56, fill: 1),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'هذا القسم قيد التطوير وسيكون متاحاً قريباً.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: AppRadius.brFull,
                ),
                child: Text(
                  'قيد التطوير',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
