import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/content/content_providers.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_assets.dart';
import '../../../shared/widgets/youtube/youtube_embed_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/floating_decoration.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../../shared/widgets/tactile/tactile_clay_progress.dart';
import '../domain/library_hub_theme.dart';
import '../domain/library_media_catalog.dart';
import 'library_media_list_screen.dart';
import 'widgets/library_track_tile.dart';

/// مشغّل clay لأصوات الطبيعة / التهويدات / الموسيقى الهادئة (تصاميم 3d_*).
class LibraryMediaHubScreen extends ConsumerStatefulWidget {
  const LibraryMediaHubScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<LibraryMediaHubScreen> createState() => _LibraryMediaHubScreenState();
}

class _LibraryMediaHubScreenState extends ConsumerState<LibraryMediaHubScreen> {
  NatureSoundChip _natureChip = NatureSoundChip.rain;
  int _itemIndex = 0;
  bool _playing = true;

  LibraryMediaCategory? get _category {
    final async = ref.watch(libraryCategoryProvider(widget.categoryId));
    return async.maybeWhen(
          data: (c) => c,
          orElse: () => null,
        ) ??
        libraryCategoryByMenuId(widget.categoryId);
  }

  LibraryHubTheme get _theme {
    final cat = _category;
    if (cat == null) return LibraryHubTheme.forCategory(LibraryMediaCategoryId.calmMusic);
    return LibraryHubTheme.forCategory(cat.id);
  }

  List<LibraryMediaItem> get _visibleItems {
    final cat = _category;
    if (cat == null) return const [];
    if (_theme.showNatureChips) {
      return libraryItemsForNatureChip(cat.items, _natureChip);
    }
    return cat.items;
  }

  LibraryMediaItem? get _currentItem {
    final items = _visibleItems;
    if (items.isEmpty) return null;
    final idx = _itemIndex.clamp(0, items.length - 1);
    return items[idx];
  }

  void _selectItem(int index) {
    setState(() {
      _itemIndex = index;
      _playing = true;
    });
  }

  void _onNatureChip(NatureSoundChip chip) {
    setState(() {
      _natureChip = chip;
      _itemIndex = 0;
      _playing = true;
    });
  }

  void _previous() {
    if (_itemIndex > 0) {
      _selectItem(_itemIndex - 1);
    }
  }

  void _next() {
    if (_itemIndex < _visibleItems.length - 1) {
      _selectItem(_itemIndex + 1);
    }
  }

  void _togglePlayPause() {
    setState(() => _playing = !_playing);
  }

  Future<void> _openInYoutube() async {
    final item = _currentItem;
    if (item == null) return;
    final uri = item.isPlaylist
        ? Uri.parse('https://www.youtube.com/playlist?list=${item.playlistId}')
        : Uri.parse('https://www.youtube.com/watch?v=${item.videoId}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openFullList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LibraryMediaListScreen(categoryId: widget.categoryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncCategory = ref.watch(libraryCategoryProvider(widget.categoryId));

    if (asyncCategory.isLoading && _category == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final category = _category;
    final theme = Theme.of(context);
    final hubTheme = _theme;

    if (category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المحتوى')),
        body: const Center(child: Text('المحتوى غير متوفر')),
      );
    }

    final items = _visibleItems;
    final current = _currentItem;
    final progress = items.isEmpty ? 0.0 : (_itemIndex + 1) / items.length;

    return Scaffold(
      backgroundColor: hubTheme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _HubHeader(
              onBack: () => context.pop(),
              onOpenYoutube: _openInYoutube,
            ),
            Expanded(
              child: Stack(
                children: [
                  if (category.id == LibraryMediaCategoryId.natureSounds) ...[
                    Positioned(
                      left: -20,
                      top: 80,
                      child: Opacity(
                        opacity: 0.35,
                        child: FloatingDecoration(
                          child: Icon(
                            Symbols.park,
                            size: 72,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -10,
                      top: 280,
                      child: Opacity(
                        opacity: 0.35,
                        child: FloatingDecoration(
                          delay: const Duration(milliseconds: 800),
                          child: Icon(
                            Symbols.eco,
                            size: 56,
                            color: AppColors.tertiary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (category.id == LibraryMediaCategoryId.calmMusic)
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _TitleSection(
                        title: category.title,
                        subtitle: hubTheme.heroSubtitle,
                        titleColor: hubTheme.titleColor,
                        icon: category.icon,
                        showBedtimeBadge:
                            category.id == LibraryMediaCategoryId.lullabies,
                      ),
                      const SizedBox(height: 16),
            _PlayerSection(
              videoId: _currentItem?.videoId,
              playlistId: _currentItem?.playlistId,
              playing: _playing,
              onPlayPause: _togglePlayPause,
              onOpenYoutube: _openInYoutube,
              accentColor: hubTheme.accentColor,
            ),
                      const SizedBox(height: 16),
                      TactileClayProgress(value: progress, height: 16),
                      const SizedBox(height: 8),
                      if (current != null)
                        Text(
                          current.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(height: 16),
                      _PlaybackControls(
                        onPrevious: _previous,
                        onNext: _next,
                        playing: _playing,
                        onPlayPause: _togglePlayPause,
                        showShuffle: category.id == LibraryMediaCategoryId.lullabies,
                        canPrevious: _itemIndex > 0,
                        canNext: _itemIndex < items.length - 1,
                      ),
                      if (hubTheme.showNatureChips) ...[
                        const SizedBox(height: 20),
                        _NatureChipsRow(
                          selected: _natureChip,
                          onSelected: _onNatureChip,
                        ),
                      ],
                      if (hubTheme.listStyle != LibraryHubListStyle.hidden) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hubTheme.listSectionTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: hubTheme.titleColor,
                              ),
                            ),
                            TextButton(
                              onPressed: _openFullList,
                              child: Text(
                                'عرض الكل',
                                style: TextStyle(
                                  color: hubTheme.titleColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(items.length, (i) {
                          final item = items[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LibraryTrackTile(
                              item: item,
                              isActive: i == _itemIndex,
                              listStyle: hubTheme.listStyle,
                              showFavorite:
                                  category.id == LibraryMediaCategoryId.lullabies,
                              onTap: () => _selectItem(i),
                            ),
                          );
                        }),
                      ] else ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: _openFullList,
                            icon: const Icon(Symbols.queue_music),
                            label: const Text('عرض كل المقاطع'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TactileClayCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Symbols.info,
                              color: AppColors.primary,
                              size: 20,
                              fill: 1,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'يتطلب اتصالاً بالإنترنت. التحكم عبر يوتيوب.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({
    required this.onBack,
    required this.onOpenYoutube,
  });

  final VoidCallback onBack;
  final VoidCallback onOpenYoutube;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: AppShadows.clayLift,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            color: AppColors.primary,
            onPressed: onBack,
          ),
          const AppLogoAvatar(size: 44, imageAsset: AppAssets.logoBaby),
          const SizedBox(width: 10),
          Text(
            'بيانور',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Material(
            color: AppColors.surfaceContainerLowest,
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onOpenYoutube,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.soft,
                ),
                child: const Icon(Symbols.open_in_new, color: AppColors.primary, fill: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.icon,
    required this.showBedtimeBadge,
  });

  final String title;
  final String subtitle;
  final Color titleColor;
  final IconData icon;
  final bool showBedtimeBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (showBedtimeBadge) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.tertiaryFixed,
              shape: BoxShape.circle,
              boxShadow: AppShadows.soft,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.tertiary, size: 32, fill: 1),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PlayerSection extends StatelessWidget {
  const _PlayerSection({
    required this.videoId,
    required this.playlistId,
    required this.playing,
    required this.onPlayPause,
    required this.onOpenYoutube,
    required this.accentColor,
  });

  final String? videoId;
  final String? playlistId;
  final bool playing;
  final VoidCallback onPlayPause;
  final Future<void> Function() onOpenYoutube;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return TactileClayCard(
      padding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          YoutubeEmbedPlayer(
            key: ValueKey('hub_${videoId}_${playlistId}_$playing'),
            videoId: videoId,
            playlistId: playlistId,
            playing: playing,
            onOpenExternal: onOpenYoutube,
            placeholderIcon: Symbols.music_note,
            placeholderIconColor: accentColor,
          ),
          if (!playing)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPlayPause,
                  borderRadius: AppRadius.brLg,
                  child: Container(
                    alignment: Alignment.center,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.clayLift,
                      ),
                      child: const Icon(
                        Symbols.play_arrow,
                        size: 40,
                        color: AppColors.onSecondaryContainer,
                        fill: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.onPrevious,
    required this.onNext,
    required this.playing,
    required this.onPlayPause,
    required this.showShuffle,
    required this.canPrevious,
    required this.canNext,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool playing;
  final VoidCallback onPlayPause;
  final bool showShuffle;
  final bool canPrevious;
  final bool canNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showShuffle)
          IconButton(
            icon: const Icon(Symbols.shuffle, color: AppColors.outline),
            onPressed: () {},
          ),
        _RoundClayButton(
          icon: Symbols.skip_previous,
          onTap: canPrevious ? onPrevious : null,
          small: true,
        ),
        const SizedBox(width: 12),
        _RoundClayButton(
          icon: playing ? Symbols.pause : Symbols.play_arrow,
          onTap: onPlayPause,
          filled: true,
        ),
        const SizedBox(width: 12),
        _RoundClayButton(
          icon: Symbols.skip_next,
          onTap: canNext ? onNext : null,
          small: true,
        ),
        if (showShuffle)
          IconButton(
            icon: const Icon(Symbols.repeat, color: AppColors.outline),
            onPressed: () {},
          ),
      ],
    );
  }
}

class _RoundClayButton extends StatelessWidget {
  const _RoundClayButton({
    required this.icon,
    required this.onTap,
    this.small = false,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool small;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final size = small ? 52.0 : 68.0;
    return Material(
      color: filled ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: onTap != null ? AppShadows.clayLift : null,
            border: filled
                ? Border(
                    bottom: BorderSide(
                      color: AppColors.primaryDim.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Icon(
            icon,
            size: small ? 28 : 36,
            color: filled ? AppColors.onPrimaryContainer : AppColors.primary,
            fill: 1,
          ),
        ),
      ),
    );
  }
}

class _NatureChipsRow extends StatelessWidget {
  const _NatureChipsRow({
    required this.selected,
    required this.onSelected,
  });

  final NatureSoundChip selected;
  final ValueChanged<NatureSoundChip> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NatureSoundChip.values.map((chip) {
          final isActive = chip == selected;
          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Material(
              color: isActive
                  ? AppColors.secondaryContainer
                  : AppColors.surfaceContainerLowest,
              borderRadius: AppRadius.brFull,
              child: InkWell(
                onTap: () => onSelected(chip),
                borderRadius: AppRadius.brFull,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.brFull,
                    boxShadow: isActive ? AppShadows.soft : AppShadows.clayLift,
                    border: isActive
                        ? Border(
                            bottom: BorderSide(
                              color: AppColors.onSecondaryContainer.withValues(alpha: 0.35),
                              width: 3,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        chip.icon,
                        size: 20,
                        color: isActive
                            ? AppColors.onSecondaryContainer
                            : AppColors.onSurfaceVariant,
                        fill: isActive ? 1 : 0,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        chip.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isActive
                                  ? AppColors.onSecondaryContainer
                                  : AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
