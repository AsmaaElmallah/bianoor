import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../application/visual_curriculum_provider.dart';
import '../domain/visual_slide.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_button.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_card.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_progress.dart';

class VisualPlayerScreen extends ConsumerStatefulWidget {
  const VisualPlayerScreen({super.key});

  @override
  ConsumerState<VisualPlayerScreen> createState() => _VisualPlayerScreenState();
}

class _VisualPlayerScreenState extends ConsumerState<VisualPlayerScreen> {
  final _audio = AudioPlayer();
  Timer? _timer;
  StreamSubscription<PlayerState>? _audioSub;
  StreamSubscription<Duration>? _positionSub;

  List<VisualRoundStep> _steps = [];
  int _stepIndex = 0;
  bool _loading = true;
  bool _advancing = false;
  double _audioProgress = 0;

  @override
  void initState() {
    super.initState();
    _audioSub = _audio.playerStateStream.listen((state) {
      if (!mounted || _advancing) return;
      if (state.processingState == ProcessingState.completed) {
        _onSlideFinished();
      }
    });
    _positionSub = _audio.positionStream.listen((pos) {
      if (!mounted) return;
      final total = _audio.duration;
      if (total == null || total.inMilliseconds <= 0) return;
      setState(() => _audioProgress = pos.inMilliseconds / total.inMilliseconds);
    });
    _load();
  }

  Future<void> _load() async {
    final steps = await ref.read(visualCurriculumProvider.notifier).buildRoundSteps();
    if (!mounted) return;
    setState(() {
      _steps = steps;
      _loading = false;
    });
    if (steps.isEmpty) return;
    await _playCurrent();
  }

  VisualRoundStep? get _current => _stepIndex < _steps.length ? _steps[_stepIndex] : null;

  double get _roundProgress => _steps.isEmpty ? 0 : (_stepIndex + _audioProgress) / _steps.length;

  Future<void> _playCurrent() async {
    final step = _current;
    if (step == null) return;

    _timer?.cancel();
    await _audio.stop();
    if (mounted) setState(() => _audioProgress = 0);

    final slide = step.slide;
    final audio = slide.audioAsset;
    if (audio != null) {
      try {
        await _audio.setAsset(audio);
        await _audio.play();
        return;
      } catch (_) {}
    }

    final sec = slide.durationSec.clamp(2.0, 120.0);
    final start = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(start).inMilliseconds / 1000.0;
      setState(() => _audioProgress = (elapsed / sec).clamp(0.0, 1.0));
      if (elapsed >= sec) _onSlideFinished();
    });
  }

  Future<void> _replayAudio() async {
    final audio = _current?.slide.audioAsset;
    if (audio == null) return;
    try {
      await _audio.setAsset(audio);
      await _audio.play();
    } catch (_) {}
  }

  Future<void> _onSlideFinished() async {
    if (_advancing || !mounted) return;
    _advancing = true;
    _timer?.cancel();
    await _audio.stop();

    if (_stepIndex + 1 < _steps.length) {
      setState(() {
        _stepIndex += 1;
        _audioProgress = 0;
        _advancing = false;
      });
      await _playCurrent();
      return;
    }

    await ref.read(visualCurriculumProvider.notifier).completeRound();
    if (!mounted) return;
    _advancing = false;
    context.pushReplacement(AppRoutes.lessonCelebrationPath('visual'));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioSub?.cancel();
    _positionSub?.cancel();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = _current;
    final curriculum = ref.watch(visualCurriculumProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'التحفيز البصري',
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          _loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'جاري تحميل شرائح الدرس...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : step == null
                  ? _EmptyState(onBack: () => context.pop())
                  : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: TactileClayProgress(value: _roundProgress, height: 12),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          Text(
                            'تحفيز بصري',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'شريحة ${step.slideIndexInLesson} من ${step.totalSlidesInLesson}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (curriculum != null)
                            Text(
                              'اليوم ${curriculum.curriculumDay} · ${_stepIndex + 1} / ${_steps.length} في الجولة',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 16),
                          _SlideDots(current: _stepIndex, total: _steps.length),
                          const SizedBox(height: 16),
                          TactileClayCard(
                            padding: const EdgeInsets.all(12),
                            child: Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: AppRadius.brLg,
                                    child: ColoredBox(
                                      color: AppColors.surfaceContainer,
                                      child: _SlideView(slide: step.slide),
                                    ),
                                  ),
                                ),
                                if (step.slide.audioAsset != null)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: _ClayIconButton(
                                      icon: Symbols.volume_up,
                                      onTap: _replayAudio,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TactileClayCard(
                            color: AppColors.tertiaryFixed.withValues(alpha: 0.55),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: AppRadius.brMd,
                                  child: Image.asset(
                                    AppAssets.logoBaby,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Symbols.emoji_emotions,
                                      size: 48,
                                      color: AppColors.tertiary,
                                      fill: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'حرّكي الشاشة ببطء',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.onTertiaryFixed,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'لتركيز انتباه طفلك — ١٥–٢٠ سم من وجهه',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.onTertiaryFixedVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _SlideDots extends StatelessWidget {
  const _SlideDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == current;
          final done = i < current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: done || active ? AppColors.primary : AppColors.outlineVariant,
              borderRadius: AppRadius.brFull,
              boxShadow: active ? AppShadows.primaryGlow : null,
            ),
          );
        }),
      ),
    );
  }
}

class _ClayIconButton extends StatelessWidget {
  const _ClayIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryContainer,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.onSecondaryContainer, fill: 1),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.info, color: AppColors.primary, size: 48, fill: 1),
            const SizedBox(height: 16),
            Text(
              'لا يوجد محتوى لهذا اليوم.\nشغّل tools/export_visual_slides.ps1 ثم أعد البناء.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TactileClayButton(
              label: 'رجوع',
              icon: Symbols.arrow_forward,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final VisualSlide slide;

  @override
  Widget build(BuildContext context) {
    final images = slide.imageAssets;
    if (images.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.broken_image, size: 56, color: AppColors.outline),
            const SizedBox(height: 8),
            Text(
              'تعذر تحميل الشريحة',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }
    if (images.length == 1) {
      return _AssetImageFit(path: images.first);
    }
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [for (final path in images) _AssetImageFit(path: path)],
    );
  }
}

class _AssetImageFit extends StatelessWidget {
  const _AssetImageFit({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'ملف غير موجود في التطبيق',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ),
      ),
    );
  }
}


