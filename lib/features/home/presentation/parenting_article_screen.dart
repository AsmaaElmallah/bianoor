import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/editorial_card.dart';
import '../domain/parenting_article.dart';

class ParentingArticleScreen extends StatelessWidget {
  const ParentingArticleScreen({super.key, required this.article});

  final ParentingArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          article.title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
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
                        color: AppColors.tertiaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Symbols.article,
                        color: AppColors.onTertiaryContainer,
                        size: 34,
                        fill: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    article.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  if (article.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      article.subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  EditorialCard(
                    accentColor: AppColors.tertiary,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Text(
                      article.body.trim(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurface,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
