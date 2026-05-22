import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../features/library/domain/library_media_catalog.dart';
import '../tactile/tactile_clay_card.dart';
import 'media_age_hub_config.dart';
import 'media_age_list_tile.dart';
import 'media_age_progress_card.dart';
import 'media_age_tactile_header.dart';

/// مشغّل clay لمحتوى عمري (تمارين / أنشطة) — tamareen-ansheta.
class MediaAgeHubScreen extends StatefulWidget {
  const MediaAgeHubScreen({
    super.key,
    required this.config,
    required this.ageTitle,
    required this.ageSubtitle,
    required this.items,
    this.parentNote,
    this.onOpenExternal,
  });

  final MediaAgeHubConfig config;
  final String ageTitle;
  final String ageSubtitle;
  final List<LibraryMediaItem> items;
  final String? parentNote;
  final Future<void> Function(LibraryMediaItem? item)? onOpenExternal;

  @override
  State<MediaAgeHubScreen> createState() => _MediaAgeHubScreenState();
}

class _MediaAgeHubScreenState extends State<MediaAgeHubScreen> {
  WebViewController? _webController;
  int _itemIndex = 0;
  bool _playing = false;
  String? _loadError;

  List<LibraryMediaItem> get _items => widget.items;

  LibraryMediaItem? get _currentItem {
    if (_items.isEmpty) return null;
    return _items[_itemIndex.clamp(0, _items.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    if (_items.isNotEmpty) {
      _loadPlayer();
    }
  }

  void _loadPlayer() {
    final item = _currentItem;
    if (item == null) return;
    final playlist = item.playlistId?.trim();
    final video = item.videoId?.trim();
    if ((playlist == null || playlist.isEmpty) && (video == null || video.isEmpty)) {
      setState(() {
        _loadError = 'لا يوجد رابط تشغيل';
        _playing = false;
      });
      return;
    }
    setState(() => _loadError = null);
    final url = libraryYoutubeEmbedUrl(videoId: video, playlistId: playlist);
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surfaceContainer)
      ..loadRequest(Uri.parse(url));
    setState(() => _playing = true);
  }

  void _selectItem(int index) {
    setState(() => _itemIndex = index);
    _loadPlayer();
  }

  void _togglePlayPause() {
    if (_playing) {
      setState(() => _playing = false);
    } else {
      _loadPlayer();
    }
  }

  Future<void> _openExternal() async {
    if (widget.onOpenExternal != null) {
      await widget.onOpenExternal!(_currentItem);
      return;
    }
    final item = _currentItem;
    if (item == null) return;
    final uri = item.isPlaylist
        ? Uri.parse('https://www.youtube.com/playlist?list=${item.playlistId}')
        : Uri.parse('https://www.youtube.com/watch?v=${item.videoId}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  int get _remainingCount {
    if (_items.isEmpty) return 0;
    return (_items.length - _itemIndex - 1).clamp(0, _items.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cfg = widget.config;
    final items = _items;
    final current = _currentItem;
    final hasContent = items.isNotEmpty;
    final headerTitle = '${cfg.kindLabel} ${widget.ageTitle}';

    Widget videoArea;
    if (_loadError != null) {
      videoArea = ColoredBox(
        color: AppColors.surfaceContainerHighest,
        child: Center(child: Text(_loadError!, textAlign: TextAlign.center)),
      );
    } else if (_playing && _webController != null) {
      videoArea = WebViewWidget(controller: _webController!);
    } else {
      final thumb = current?.youtubeThumbnailUrl;
      videoArea = thumb != null
          ? Image.network(thumb, fit: BoxFit.cover)
          : ColoredBox(
              color: AppColors.surfaceContainerHighest,
              child: Icon(Symbols.fitness_center, size: 56, color: cfg.accentColor),
            );
    }

    return Scaffold(
      backgroundColor: cfg.scaffoldBackground,
      body: Column(
        children: [
          MediaAgeTactileHeader(
            title: headerTitle,
            onBack: () => context.pop(),
            onAction: _openExternal,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                if (!hasContent) ...[
                  TactileClayCard(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      widget.parentNote ?? 'لا يوجد محتوى لهذا العمر بعد.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                ] else ...[
                  MediaAgeFeaturedCard(
                    title: current!.title,
                    subtitle: current.moodTag ?? widget.ageSubtitle,
                    durationLabel: current.durationLabel,
                    videoArea: videoArea,
                    playing: _playing,
                    onPlayPause: _togglePlayPause,
                    accentColor: cfg.accentColor,
                  ),
                  if (widget.parentNote != null) ...[
                    const SizedBox(height: 12),
                    TactileClayCard(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.25),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Symbols.info, color: AppColors.secondary, size: 20, fill: 1),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.parentNote!,
                              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cfg.listSectionTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: AppRadius.brFull,
                        ),
                        child: Text(
                          _remainingCount == 0
                              ? 'اكتملت المجموعة'
                              : '$_remainingCount ${_remainingCount == 1 ? 'مقطع متبقي' : 'مقاطع متبقية'}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(items.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MediaAgeListTile(
                        item: items[i],
                        isActive: i == _itemIndex,
                        isCompleted: i < _itemIndex,
                        onTap: () => _selectItem(i),
                        accentColor: cfg.accentColor,
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  MediaAgeProgressCard(
                    title: cfg.progressTitle,
                    subtitle: '',
                    current: _itemIndex + 1,
                    total: items.length,
                    accentColor: cfg.accentColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
