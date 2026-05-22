import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/editorial_card.dart';
import '../domain/curriculum_about_content.dart';

class CurriculumAboutScreen extends StatelessWidget {
  const CurriculumAboutScreen({super.key});

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
          'ما هو المنهج؟',
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
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Symbols.auto_stories,
                        color: AppColors.onPrimaryContainer,
                        size: 34,
                        fill: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    curriculumAboutTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...curriculumAboutParagraphs.map(
                    (paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: EditorialCard(
                        accentColor:
                            paragraph.isPhaseOne ? AppColors.secondary : AppColors.primary,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              paragraph.isPhaseOne ? Symbols.child_care : Symbols.spa,
                              color: paragraph.isPhaseOne
                                  ? AppColors.secondary
                                  : AppColors.primary,
                              size: 24,
                              fill: 1,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                paragraph.text,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.onSurface,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
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
