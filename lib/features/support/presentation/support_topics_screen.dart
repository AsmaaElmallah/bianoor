import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../domain/support_topics_data.dart';

class SupportTopicsScreen extends StatelessWidget {
  const SupportTopicsScreen({
    super.key,
    required this.title,
    required this.topics,
  });

  final String title;
  final List<SupportTopicItem> topics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              children: topics.map((topic) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TopicTile(topic: topic, theme: theme),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicTile extends StatefulWidget {
  const _TopicTile({required this.topic, required this.theme});

  final SupportTopicItem topic;
  final ThemeData theme;

  @override
  State<_TopicTile> createState() => _TopicTileState();
}

class _TopicTileState extends State<_TopicTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return TactileClayCard(
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(widget.topic.icon, color: AppColors.error, size: 22, fill: 1),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.topic.title,
                  style: widget.theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                _open ? Symbols.expand_less : Symbols.expand_more,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: 12),
            Text(
              widget.topic.body,
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
