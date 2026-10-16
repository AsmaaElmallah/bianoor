import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/ai_models.dart';

Future<void> openAiLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح الرابط')));
  }
}

/// «المصادر» row — references come from Bayanour's library, never from the AI.
class AiSourcesRow extends StatelessWidget {
  const AiSourcesRow({super.key, required this.sources});

  final List<AiSource> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المصادر العلمية',
          style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in sources)
              ActionChip(
                avatar: const Icon(Symbols.verified, size: 16, color: AppColors.tertiaryDim),
                label: Text(s.title, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                backgroundColor: AppColors.tertiaryContainer,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                onPressed: s.url == null || s.url!.isEmpty ? null : () => openAiLink(context, s.url!),
              ),
          ],
        ),
      ],
    );
  }
}

class AiDisclaimer extends StatelessWidget {
  const AiDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: AppRadius.brMd),
      child: Row(
        children: [
          const Icon(Symbols.info, size: 18, color: AppColors.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'إجابات من مصادر طبية وتربوية موثوقة (WHO، AAP، CDC، NHS) — ومش بديل عن الطبيب.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
