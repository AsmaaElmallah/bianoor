import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_logo_avatar.dart';
import '../../../../shared/widgets/youtube/youtube_fullscreen_player.dart';
import '../../../../shared/widgets/youtube/youtube_thumbnail.dart';
import '../../../library/data/library_pdf_repository.dart';
import '../../../library/data/library_sections_repository.dart';
import '../../../library/domain/library_age_band.dart';
import '../../../library/domain/library_pdf.dart';
import '../../../library/domain/library_section_items.dart';
import '../../../library/presentation/library_pdf_viewer_screen.dart';

enum _LibrarySection {
  pdf('كتب PDF', Symbols.picture_as_pdf),
  paid('كتب مدفوعة', Symbols.shopping_bag),
  visual('تحفيز بصري', Symbols.visibility);

  const _LibrarySection(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _cardRadius = BorderRadius.all(Radius.circular(32));
const _innerRadius = BorderRadius.all(Radius.circular(16));

class _Accent {
  const _Accent(this.color, this.light);
  final Color color;
  final Color light;
}

const _accents = <_Accent>[
  _Accent(AppColors.primary, AppColors.primaryContainer),
  _Accent(AppColors.secondary, AppColors.secondaryContainer),
  _Accent(AppColors.tertiary, AppColors.tertiaryContainer),
  _Accent(AppColors.secondary, AppColors.secondaryContainer),
  _Accent(AppColors.primary, AppColors.primaryContainer),
  _Accent(AppColors.tertiary, AppColors.tertiaryContainer),
];

List<BoxShadow> _clayShadow(Color tint, {double alpha = 0.07, double blur = 24, double y = 8}) => [
      BoxShadow(
        color: tint.withValues(alpha: alpha),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
      const BoxShadow(
        color: Color(0xE6FFFFFF),
        blurRadius: 0,
        offset: Offset(-1, -1.5),
      ),
    ];

class LibraryTab extends ConsumerStatefulWidget {
  const LibraryTab({super.key});

  @override
  ConsumerState<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<LibraryTab> {
  final _searchFocus = FocusNode();
  LibraryAgeBand _band = LibraryAgeBand.m0to3;
  _LibrarySection _section = _LibrarySection.pdf;
  String _query = '';
  bool _opening = false;

  bool _matches(String title, String description, [String extra = '']) {
    final q = _query.trim();
    if (q.isEmpty) return true;
    return title.contains(q) || description.contains(q) || extra.contains(q);
  }

  List<LibraryPdf> _filter(List<LibraryPdf> all) {
    return all
        .where((pdf) =>
            pdf.ageBand == _band && _matches(pdf.title, pdf.description, pdf.tagLabel))
        .toList();
  }

  Future<void> _refreshCurrent() {
    switch (_section) {
      case _LibrarySection.pdf:
        return ref.refresh(libraryPdfsProvider.future);
      case _LibrarySection.paid:
        ref.invalidate(libraryWhatsappNumberProvider);
        return ref.refresh(libraryPaidBooksProvider.future);
      case _LibrarySection.visual:
        return ref.refresh(libraryVisualVideosProvider.future);
    }
  }

  Future<void> _contactForBook(LibraryPaidBook book) async {
    final number = await ref.read(libraryWhatsappNumberProvider.future);
    if (!mounted) return;
    if (number.isEmpty) {
      _snack('رقم التواصل غير متاح حالياً، حاولي لاحقاً.');
      return;
    }
    final uri = Uri.https('wa.me', '/$number', {
      'text': 'مرحباً، أرغب في شراء كتاب: ${book.title}',
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack('تعذّر فتح واتساب، تأكدي أنه مثبت على جهازك.');
  }

  void _playVisual(LibraryVisualVideo video) {
    openYoutubeFullscreen(
      context,
      videoId: video.youtubeVideoId,
      videoUrl: video.videoUrl,
    );
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _openReader(LibraryPdf pdf) {
    if (!pdf.hasFile) {
      _snack('هذا الملف غير متاح حالياً.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LibraryPdfViewerScreen(pdf: pdf)),
    );
  }

  Future<void> _openFile(LibraryPdf pdf, {bool download = false}) async {
    if (!pdf.hasFile) {
      _snack('هذا الملف غير متاح حالياً.');
      return;
    }
    if (_opening) return;
    setState(() => _opening = true);
    final uri = await ref
        .read(libraryPdfRepositoryProvider)
        .signedUrl(pdf, download: download);
    if (!mounted) return;
    setState(() => _opening = false);
    if (uri == null) {
      _snack('تعذّر تجهيز الملف، تأكدي من تسجيل الدخول والاتصال بالإنترنت.');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack('تعذّر فتح الملف، حاولي مرة أخرى.');
  }

  void _showReader(LibraryPdf pdf, _Accent accent) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.inverseSurface.withValues(alpha: 0.55),
      builder: (dialogContext) => _PdfReaderDialog(
        pdf: pdf,
        accent: accent,
        onRead: () {
          Navigator.of(dialogContext).pop();
          _openReader(pdf);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshCurrent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          _LibraryHeader(onSearch: () => _searchFocus.requestFocus()),
          const SizedBox(height: 20),
          _IntroBanner(
            focusNode: _searchFocus,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 20),
          _AgeChips(
            selected: _band,
            onSelected: (b) => setState(() => _band = b),
          ),
          const SizedBox(height: 14),
          _SectionTabs(
            selected: _section,
            onSelected: (s) => setState(() => _section = s),
          ),
          const SizedBox(height: 20),
          ..._buildSection(),
        ],
      ),
    );
  }

  List<Widget> _buildSection() {
    switch (_section) {
      case _LibrarySection.pdf:
        return [
          ..._asyncList(
            ref.watch(libraryPdfsProvider),
            onRetry: () => ref.invalidate(libraryPdfsProvider),
            builder: _buildCards,
          ),
          const SizedBox(height: 8),
          const _FriendlyNotice(),
        ];
      case _LibrarySection.paid:
        return _asyncList(
          ref.watch(libraryPaidBooksProvider),
          onRetry: () => ref.invalidate(libraryPaidBooksProvider),
          builder: _buildPaidBooks,
        );
      case _LibrarySection.visual:
        return _asyncList(
          ref.watch(libraryVisualVideosProvider),
          onRetry: () => ref.invalidate(libraryVisualVideosProvider),
          builder: _buildVisualVideos,
        );
    }
  }

  List<Widget> _asyncList<T>(
    AsyncValue<List<T>> value, {
    required VoidCallback onRetry,
    required List<Widget> Function(List<T>) builder,
  }) {
    return value.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ],
      error: (_, __) => [
        _StateMessage(
          icon: Symbols.cloud_off,
          title: 'تعذّر تحميل المكتبة',
          subtitle: 'تأكدي من الاتصال بالإنترنت ثم اسحبي الصفحة للتحديث.',
          actionLabel: 'إعادة المحاولة',
          onAction: onRetry,
        ),
      ],
      data: builder,
    );
  }

  Widget _emptyForBand(IconData icon, String what) {
    return _StateMessage(
      icon: icon,
      title: 'لا توجد $what لعمر ${_band.label} بعد',
      subtitle: 'سيضيف فريق بيانور المزيد قريباً، أو جرّبي عمراً آخر.',
    );
  }

  List<Widget> _buildPaidBooks(List<LibraryPaidBook> all) {
    final inBand = all.where((b) => b.ageBand == _band).toList();
    if (inBand.isEmpty) return [_emptyForBand(Symbols.shopping_bag, 'كتب مدفوعة')];
    final visible = inBand.where((b) => _matches(b.title, b.description)).toList();
    if (visible.isEmpty) return const [_NoResults()];
    return [
      for (final book in visible) ...[
        _PaidBookCard(book: book, onContact: () => _contactForBook(book)),
        const SizedBox(height: 16),
      ],
    ];
  }

  List<Widget> _buildVisualVideos(List<LibraryVisualVideo> all) {
    final inBand = all.where((v) => v.ageBand == _band).toList();
    if (inBand.isEmpty) return [_emptyForBand(Symbols.visibility, 'فيديوهات تحفيز بصري')];
    final visible = inBand.where((v) => _matches(v.title, v.description)).toList();
    if (visible.isEmpty) return const [_NoResults()];
    return [
      for (final video in visible) ...[
        _VisualVideoCard(video: video, onPlay: () => _playVisual(video)),
        const SizedBox(height: 16),
      ],
    ];
  }

  List<Widget> _buildCards(List<LibraryPdf> all) {
    final inBand = all.where((p) => p.ageBand == _band).toList();
    if (inBand.isEmpty) return [_emptyForBand(Symbols.auto_stories, 'كتب PDF')];
    final visible = _filter(all);
    if (visible.isEmpty) return const [_NoResults()];
    return [
      for (final pdf in visible) ...[
        Builder(builder: (context) {
          final index = all.indexOf(pdf);
          final accent = _accents[index % _accents.length];
          return _PdfCard(
            pdf: pdf,
            accent: accent,
            ctaLabel: index.isEven ? 'فتح الـ PDF' : 'عرض الملف',
            onOpen: () => _showReader(pdf, accent),
            onDownload: () => _openFile(pdf, download: true),
          );
        }),
        const SizedBox(height: 16),
      ],
    ];
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogoAvatar(size: 44, imageAsset: AppAssets.logoBaby),
                const SizedBox(width: 12),
                Text(
                  'بيانور',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
              boxShadow: _clayShadow(AppColors.primary, alpha: 0.06, blur: 16, y: 6),
            ),
            child: Text(
              'المكتبة',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                height: 1.1,
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Material(
              color: AppColors.surfaceContainerLowest,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSearch,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: _clayShadow(AppColors.onSurface, alpha: 0.05, blur: 10, y: 4),
                  ),
                  child: const Icon(Symbols.search, size: 22, color: AppColors.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({required this.focusNode, required this.onChanged});

  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: _cardRadius,
        boxShadow: _clayShadow(AppColors.primary, alpha: 0.07, blur: 32, y: 12),
      ),
      child: Stack(
        children: [
          const PositionedDirectional(
            top: -40,
            end: -40,
            child: _SoftOrb(size: 128, color: AppColors.primaryFixed),
          ),
          const PositionedDirectional(
            bottom: -32,
            start: -32,
            child: _SoftOrb(size: 112, color: AppColors.tertiaryFixed),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.child_care, size: 16, fill: 1, color: AppColors.onPrimaryFixed),
                      const SizedBox(width: 6),
                      Text(
                        'محتوى حسب عمر طفلك',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimaryFixed,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'مكتبة بيانور',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اختاري عمر طفلك لتجدي كتب PDF للقراءة والتحميل، وكتباً مطبوعة للطلب، وفيديوهات تحفيز بصري مناسبة لمرحلته.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                _InsetSearchField(focusNode: focusNode, onChanged: onChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _InsetSearchField extends StatelessWidget {
  const _InsetSearchField({required this.focusNode, required this.onChanged});

  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: _innerRadius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceContainer, AppColors.surfaceContainerLow],
        ),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: TextField(
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: 'ابحثي في المكتبة...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(color: AppColors.outline),
          prefixIcon: const Icon(Symbols.search, size: 22, color: AppColors.onSurfaceVariant),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Text(
                'PDF',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class _AgeChips extends StatelessWidget {
  const _AgeChips({required this.selected, required this.onSelected});

  final LibraryAgeBand selected;
  final ValueChanged<LibraryAgeBand> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final band in LibraryAgeBand.values) ...[
            if (band != LibraryAgeBand.values.first) const SizedBox(width: 8),
            _Chip(
              label: band.label,
              icon: Symbols.child_care,
              active: selected == band,
              onTap: () => onSelected(band),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.selected, required this.onSelected});

  final _LibrarySection selected;
  final ValueChanged<_LibrarySection> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          for (final section in _LibrarySection.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(section),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected == section
                        ? AppColors.surfaceContainerLowest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: selected == section
                        ? _clayShadow(AppColors.primary, alpha: 0.08, blur: 10, y: 3)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        section.icon,
                        size: 20,
                        fill: selected == section ? 1 : 0,
                        color: selected == section
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        section.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected == section
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaidBookCard extends StatelessWidget {
  const _PaidBookCard({required this.book, required this.onContact});

  final LibraryPaidBook book;
  final VoidCallback onContact;

  static const _whatsappGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = book.coverUrl?.trim();
    final fallback = ColoredBox(
      color: AppColors.secondaryContainer,
      child: Center(
        child: Icon(Symbols.menu_book, size: 48, color: AppColors.secondary, fill: 1),
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: _cardRadius,
        boxShadow: _clayShadow(AppColors.primary, alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: cover != null && cover.isNotEmpty
                ? Image.network(
                    cover,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : fallback,
                  )
                : fallback,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                if (book.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    book.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: onContact,
                    style: FilledButton.styleFrom(
                      backgroundColor: _whatsappGreen,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: _innerRadius),
                    ),
                    icon: const Icon(Symbols.chat, size: 20, fill: 1),
                    label: const Text('تواصلي معنا عبر واتساب'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualVideoCard extends StatelessWidget {
  const _VisualVideoCard({required this.video, required this.onPlay});

  final LibraryVisualVideo video;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: _cardRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPlay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  YoutubeThumbnail(
                    videoId: video.youtubeVideoId,
                    imageUrl: video.coverUrl,
                    icon: Symbols.visibility,
                  ),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(
                        Symbols.play_arrow,
                        size: 40,
                        color: AppColors.primary,
                        fill: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (video.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.onPrimary : AppColors.onSurfaceVariant;
    return Material(
      color: active ? AppColors.primary : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : _clayShadow(AppColors.onSurface, alpha: 0.04, blur: 10, y: 4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfCard extends StatelessWidget {
  const _PdfCard({
    required this.pdf,
    required this.accent,
    required this.ctaLabel,
    required this.onOpen,
    required this.onDownload,
  });

  final LibraryPdf pdf;
  final _Accent accent;
  final String ctaLabel;
  final VoidCallback onOpen;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = pdf.pagesText;
    final size = pdf.sizeText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: _cardRadius,
        boxShadow: _clayShadow(AppColors.primary, alpha: 0.06),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PdfCover(pdf: pdf, accent: accent),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 128,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pdf.tagLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accent.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pdf.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pdf.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (pages != null || size != null)
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (pages != null) _Meta(icon: Symbols.description, text: pages),
                            if (pages != null && size != null) const _MetaDot(),
                            if (size != null) _Meta(icon: Symbols.save, text: size),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: accent.color,
                  borderRadius: _innerRadius,
                  child: InkWell(
                    onTap: onOpen,
                    borderRadius: _innerRadius,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: _innerRadius,
                        boxShadow: [
                          BoxShadow(
                            color: accent.color.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Symbols.visibility, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            ctaLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'تحميل سريع',
                child: Material(
                  color: AppColors.surfaceContainer,
                  borderRadius: _innerRadius,
                  child: InkWell(
                    onTap: onDownload,
                    borderRadius: _innerRadius,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Symbols.download, size: 20, color: accent.color),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PdfCover extends StatelessWidget {
  const _PdfCover({required this.pdf, required this.accent});

  final LibraryPdf pdf;
  final _Accent accent;

  @override
  Widget build(BuildContext context) {
    final url = pdf.coverUrl;
    final fallback = Center(
      child: Icon(Symbols.auto_stories, size: 40, color: accent.color, fill: 1),
    );

    return Container(
      width: 96,
      height: 128,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accent.light,
        borderRadius: _innerRadius,
        boxShadow: [
          BoxShadow(
            color: accent.color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url.isNotEmpty)
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : fallback,
            )
          else
            fallback,
          PositionedDirectional(
            top: 6,
            start: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PDF',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onError,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.hintPlaceholder,
          ),
        ),
      ],
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '•',
      style: TextStyle(fontSize: 12, color: AppColors.outline),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: _cardRadius,
        boxShadow: _clayShadow(AppColors.primary, alpha: 0.04, blur: 12, y: 4),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Symbols.search_off, size: 32, color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          Text(
            'لم نعثر على هذا الـ PDF',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تأكدي من كتابة اسم الكتيب أو اختاري من التصنيفات أعلاه.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: _cardRadius,
        boxShadow: _clayShadow(AppColors.primary, alpha: 0.04, blur: 12, y: 4),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _FriendlyNotice extends StatelessWidget {
  const _FriendlyNotice();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.onPrimaryFixedVariant,
          height: 1.5,
        );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.7),
        borderRadius: _cardRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Symbols.cloud_done, size: 20, color: AppColors.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: style,
                children: const [
                  TextSpan(text: 'جميع ملفات الـ PDF تفتح مباشرة وبسلاسة داخل تطبيق '),
                  TextSpan(text: 'بيانور', style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: ' ويمكنك تحميلها على جهازك ✨'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfReaderDialog extends StatelessWidget {
  const _PdfReaderDialog({
    required this.pdf,
    required this.accent,
    required this.onRead,
  });

  final LibraryPdf pdf;
  final _Accent accent;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = [pdf.pagesText, pdf.sizeText, 'تحميل فوري'].whereType<String>().join(' • ');

    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: _cardRadius),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Symbols.picture_as_pdf, size: 20, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'قارئ بيانور المدمج',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
                Material(
                  color: AppColors.surfaceContainer,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(Symbols.close, size: 18, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                color: accent.light,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Symbols.auto_stories, size: 36, color: accent.color),
            ),
            const SizedBox(height: 12),
            Text(
              pdf.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: onRead,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const RoundedRectangleBorder(borderRadius: _innerRadius),
                ),
                icon: const Icon(Symbols.chrome_reader_mode, size: 20),
                label: const Text('بدء القراءة الآن'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainer,
                  foregroundColor: AppColors.onSurfaceVariant,
                  shape: const RoundedRectangleBorder(borderRadius: _innerRadius),
                ),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
