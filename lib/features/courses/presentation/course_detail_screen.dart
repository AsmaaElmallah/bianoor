import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/youtube/youtube_fullscreen_player.dart';
import '../../library/data/library_sections_repository.dart';
import '../../payments/data/payment_settings_repository.dart';
import '../../payments/domain/payment_item.dart';
import '../../payments/presentation/payment_options_sheet.dart';
import '../data/course_purchase_service.dart';
import '../data/courses_repository.dart';
import '../domain/course.dart';
import 'course_lesson_player_screen.dart';
import 'widgets/course_access_badge.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.course});

  final Course course;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(courseAccessProvider(course.id));
    ref.invalidate(courseProgressProvider(course.id));
    ref.invalidate(courseLessonsProvider(course.id));
    await ref.read(courseLessonsProvider(course.id).future);
  }

  Future<void> _openLesson(
    BuildContext context,
    WidgetRef ref,
    List<CourseLesson> lessons,
    int index,
  ) async {
    final lesson = lessons[index];
    if (lesson.isYoutube) {
      await openYoutubeFullscreen(context, videoId: lesson.youtubeVideoId);
      await ref.read(coursesRepositoryProvider).saveProgress(
            lesson: lesson,
            positionSeconds: 0,
            completed: true,
          );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CourseLessonPlayerScreen(
            course: course,
            lessons: lessons,
            initialIndex: index,
          ),
        ),
      );
    }
    ref.invalidate(courseProgressProvider(course.id));
  }

  Future<void> _contactForCourse(BuildContext context, WidgetRef ref) async {
    final number = await ref.read(libraryWhatsappNumberProvider.future);
    if (!context.mounted) return;
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم التواصل غير متاح حالياً، حاولي لاحقاً.')),
      );
      return;
    }
    final uri = Uri.https('wa.me', '/$number', {
      'text': 'مرحباً، أرغب في الاشتراك في دورة: ${course.title}',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncLessons = ref.watch(courseLessonsProvider(course.id));
    final hasAccess = ref.watch(courseAccessProvider(course.id)).valueOrNull ?? false;
    final progress = ref.watch(courseProgressProvider(course.id)).valueOrNull ?? const {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CourseCover(url: course.coverUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Colors.transparent],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverList.list(
                children: [
                  Align(alignment: AlignmentDirectional.centerStart, child: CourseAccessBadge(course: course)),
                  const SizedBox(height: 10),
                  Text(
                    course.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (course.instructorName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Symbols.person, size: 18, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          course.instructorName,
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                  if (course.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      course.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                        height: 1.6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  asyncLessons.maybeWhen(
                    data: (lessons) => hasAccess
                        ? _ProgressSummary(lessons: lessons, progress: progress)
                        : _LockedBanner(
                            course: course,
                            onSubscribe: () => context.push(AppRoutes.subscription),
                            onContact: () => _contactForCourse(context, ref),
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'الدروس',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            asyncLessons.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('تعذّر تحميل الدروس، اسحبي لتحت للمحاولة تاني.', textAlign: TextAlign.center),
                ),
              ),
              data: (lessons) {
                if (lessons.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('الدروس هتنزل قريب 🌸', textAlign: TextAlign.center),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList.separated(
                    itemCount: lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final unlocked = hasAccess || lesson.isPreview;
                      return _LessonTile(
                        index: index,
                        lesson: lesson,
                        unlocked: unlocked,
                        completed: progress[lesson.id]?.completed ?? false,
                        onTap: unlocked
                            ? () => _openLesson(context, ref, lessons, index)
                            : () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('الدرس ده مقفول — افتحي الدورة الأول.')),
                                ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.lessons, required this.progress});

  final List<CourseLesson> lessons;
  final Map<String, LessonProgress> progress;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();
    final done = lessons.where((l) => progress[l.id]?.completed ?? false).length;
    final ratio = done / lessons.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            done == lessons.length ? 'خلّصتي الدورة كلها 🎉' : 'خلّصتي $done من ${lessons.length} درس',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.primaryContainer,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBanner extends ConsumerStatefulWidget {
  const _LockedBanner({required this.course, required this.onSubscribe, required this.onContact});

  final Course course;
  final VoidCallback onSubscribe;
  final VoidCallback onContact;

  @override
  ConsumerState<_LockedBanner> createState() => _LockedBannerState();
}

class _LockedBannerState extends ConsumerState<_LockedBanner> {
  bool _buying = false;

  Future<void> _buy() async {
    setState(() => _buying = true);
    final result = await ref.read(coursePurchaseServiceProvider).buy(widget.course);
    if (!mounted) return;
    setState(() => _buying = false);
    if (result.outcome == CoursePurchaseOutcome.success) {
      ref.invalidate(courseAccessProvider(widget.course.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم فتح الدورة 🎉 استمتعي بالدروس')),
      );
    } else if (result.outcome != CoursePurchaseOutcome.cancelled && result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _choosePayment(String? storePrice) async {
    final course = widget.course;
    final choice = await showPaymentOptions(
      context,
      item: PaymentItem(
        kind: PaymentKind.course,
        id: course.id,
        title: course.title,
        priceLabel: course.priceLabel,
        priceUsd: course.priceUsd,
      ),
      storeLabel: storePrice == null ? null : 'Google Play — $storePrice',
    );
    if (!mounted) return;
    switch (choice) {
      case PaymentChoice.store:
        await _buy();
      case PaymentChoice.paidOnline:
        ref.invalidate(courseAccessProvider(course.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم فتح الدورة 🎉 استمتعي بالدروس')),
        );
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final onSubscribe = widget.onSubscribe;
    final onContact = widget.onContact;
    final isSubscription = course.accessType == CourseAccessType.subscription;
    final storePrice = isSubscription ? null : ref.watch(courseStorePriceProvider(course)).valueOrNull;
    final settings = ref.watch(paymentSettingsProvider).valueOrNull ?? const PaymentSettings();
    final canPaypal = settings.paypalEnabled && course.priceUsd != null;
    final canBuy = storePrice != null || canPaypal || settings.canPayManually;
    final priceText = storePrice ?? (course.priceLabel.isNotEmpty ? course.priceLabel : formatUsd(course.priceUsd));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.lock, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSubscription ? 'الدورة دي للمشتركات في الباقة' : 'الدورة دي مدفوعة',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isSubscription
                ? 'اشتركي علشان تفتحي كل الدروس. الدروس التجريبية متاحة دلوقتي.'
                : canBuy
                    ? 'اشتري الدورة مرة واحدة وتفضل معاكي على طول. الدروس التجريبية متاحة دلوقتي.'
                    : 'تواصلي معانا علشان نفتحلك الدورة${course.priceLabel.isNotEmpty ? ' (${course.priceLabel})' : ''}. الدروس التجريبية متاحة دلوقتي.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _buying
                  ? null
                  : isSubscription
                      ? onSubscribe
                      : canBuy
                          ? () => _choosePayment(storePrice)
                          : onContact,
              icon: _buying
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(isSubscription
                      ? Symbols.workspace_premium
                      : canBuy
                          ? Symbols.shopping_bag
                          : Symbols.chat),
              label: Text(isSubscription
                  ? 'اشتركي الآن'
                  : canBuy
                      ? (priceText != null ? 'اشتري الدورة — $priceText' : 'اشتري الدورة')
                      : 'تواصلي على واتساب'),
            ),
          ),
          if (canBuy)
            Center(
              child: TextButton(
                onPressed: onContact,
                child: const Text('عندك سؤال؟ تواصلي معانا على واتساب'),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.index,
    required this.lesson,
    required this.unlocked,
    required this.completed,
    required this.onTap,
  });

  final int index;
  final CourseLesson lesson;
  final bool unlocked;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (lesson.durationLabel != null) lesson.durationLabel!,
      if (lesson.isPreview && !completed) 'تجريبي',
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: completed ? AppColors.tertiaryContainer : AppColors.primaryContainer,
                child: completed
                    ? const Icon(Symbols.check, size: 18, color: AppColors.tertiary)
                    : Text(
                        '${index + 1}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryDim,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: unlocked ? AppColors.onSurface : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Icon(
                unlocked ? Symbols.play_circle : Symbols.lock,
                color: unlocked ? AppColors.primary : AppColors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
