import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../data/library_pdf_repository.dart';
import '../domain/library_pdf.dart';

/// قارئ PDF داخل التطبيق — يحمّل الملف من bucket «library-pdfs» الخاص.
class LibraryPdfViewerScreen extends ConsumerStatefulWidget {
  const LibraryPdfViewerScreen({super.key, required this.pdf});

  final LibraryPdf pdf;

  @override
  ConsumerState<LibraryPdfViewerScreen> createState() => _LibraryPdfViewerScreenState();
}

class _LibraryPdfViewerScreenState extends ConsumerState<LibraryPdfViewerScreen> {
  PdfControllerPinch? _controller;
  Object? _error;
  int _page = 1;
  int? _pagesCount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _controller?.dispose();
      _controller = null;
    });
    try {
      final bytes = await ref.read(libraryPdfRepositoryProvider).downloadBytes(widget.pdf);
      if (!mounted) return;
      setState(() {
        _controller = PdfControllerPinch(document: PdfDocument.openData(bytes));
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _download() async {
    final uri = await ref
        .read(libraryPdfRepositoryProvider)
        .signedUrl(widget.pdf, download: true);
    if (!mounted) return;
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحميل الملف، حاولي مرة أخرى.')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainer,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        titleSpacing: 0,
        title: Text(
          widget.pdf.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'تحميل',
            onPressed: _download,
            icon: const Icon(Symbols.download, color: AppColors.primary),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBody(theme)),
          if (_controller != null && _pagesCount != null)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inverseSurface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$_page / $_pagesCount',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.inverseOnSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return _Message(
        icon: Symbols.cloud_off,
        title: 'تعذّر فتح الملف',
        subtitle: 'تأكدي من الاتصال بالإنترنت وتسجيل الدخول.',
        actionLabel: 'إعادة المحاولة',
        onAction: _load,
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const _Message(
        icon: Symbols.picture_as_pdf,
        title: 'جاري تجهيز الملف…',
        subtitle: 'قد يستغرق ذلك لحظات حسب حجم الملف.',
        loading: true,
      );
    }
    return PdfViewPinch(
      controller: controller,
      padding: 12,
      backgroundDecoration: const BoxDecoration(color: AppColors.surfaceContainer),
      onDocumentLoaded: (doc) => setState(() => _pagesCount = doc.pagesCount),
      onPageChanged: (page) => setState(() => _page = page),
      onDocumentError: (e) => setState(() => _error = e),
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
        pageLoaderBuilder: (_) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            if (loading) ...[
              const SizedBox(height: 20),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
