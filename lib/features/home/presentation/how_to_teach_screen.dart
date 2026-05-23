import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../../shared/widgets/editorial_card.dart';
import '../domain/how_to_teach_content.dart';
import '../domain/parenting_article.dart';
import '../domain/parenting_articles_how_to_teach.dart';
import 'parenting_article_screen.dart';

class HowToTeachScreen extends StatelessWidget {
  const HowToTeachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'كيف أدرس طفلي',
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Symbols.school,
                        color: AppColors.onSecondaryContainer,
                        size: 34,
                        fill: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    howToTeachTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...howToTeachBlocks.map((block) => _buildBlockCard(context, theme, block)),
                  const SizedBox(height: 8),
                  Text(
                    'مقالات إرشادية',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ArticleLinkCard(
                    article: teachEmotional0to2Article,
                    accent: AppColors.tertiary,
                    icon: Symbols.favorite,
                  ),
                  const SizedBox(height: 10),
                  _ArticleLinkCard(
                    article: discoverAptitudes0to2Article,
                    accent: AppColors.primary,
                    icon: Symbols.psychology,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockCard(
    BuildContext context,
    ThemeData theme,
    HowToTeachBlock block,
  ) {
    final isAgeRange = block.kind == HowToTeachBlockKind.ageRange;
    final accent = isAgeRange ? AppColors.tertiary : AppColors.secondary;
    final icon = isAgeRange ? Symbols.nest_clock_farsight_analog : Symbols.spa;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EditorialCard(
        accentColor: accent,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 24, fill: 1),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                block.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleLinkCard extends StatelessWidget {
  const _ArticleLinkCard({
    required this.article,
    required this.accent,
    required this.icon,
  });

  final ParentingArticle article;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ParentingArticleScreen(article: article),
            ),
          );
        },
        child: EditorialCard(
          accentColor: accent,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 28, fill: 1),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (article.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        article.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
