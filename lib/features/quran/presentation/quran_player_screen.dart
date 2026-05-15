import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../application/quran_curriculum_provider.dart';
import '../domain/quran_age_schedule.dart';
import 'widgets/tactile/quran_floating_hero.dart';
import 'widgets/tactile/quran_tactile_app_bar.dart';
import 'widgets/tactile/tactile_clay_button.dart';
import 'widgets/tactile/tactile_clay_card.dart';
import 'widgets/tactile/tactile_clay_progress.dart';

class QuranPlayerScreen extends ConsumerStatefulWidget {
  const QuranPlayerScreen({super.key});

  @override
  ConsumerState<QuranPlayerScreen> createState() => _QuranPlayerScreenState();
}

class _QuranPlayerScreenState extends ConsumerState<QuranPlayerScreen> {
  final _player = AudioPlayer();
  Timer? _fallbackTimer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  Duration _elapsed = Duration.zero;
  Duration _total = const Duration(minutes: 15);
  bool _playing = false;
  bool _audioLoaded = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final session = ref.read(quranCurriculumProvider).currentSession;
    final asset = session.localAsset;
    if (asset == null) return;
    try {
      await _player.setAsset(asset);
      final duration = _player.duration;
      if (duration != null && duration > Duration.zero) {
        if (!mounted) return;
        setState(() {
          _audioLoaded = true;
          _total = duration;
        });
        _positionSub = _player.positionStream.listen((pos) {
          if (!mounted || _completed) return;
          setState(() => _elapsed = pos);
        });
        _playerStateSub = _player.playerStateStream.listen((playerState) {
          if (!mounted || _completed) return;
          if (playerState.processingState == ProcessingState.completed) {
            _onSessionFinished();
          }
          setState(() => _playing = playerState.playing);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _audioLoaded = false);
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _seekTo(Duration position) async {
    if (!_audioLoaded || _completed) return;
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > _total ? _total : position);
    await _player.seek(clamped);
    if (mounted) setState(() => _elapsed = clamped);
  }

  void _skipBy(Duration delta) => _seekTo(_elapsed + delta);

  void _togglePlay() {
    if (_completed) return;
    if (_audioLoaded) {
      _playing ? _player.pause() : _player.play();
      return;
    }
    if (_playing) {
      _fallbackTimer?.cancel();
      setState(() => _playing = false);
    } else {
      _fallbackTimer?.cancel();
      _fallbackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed += const Duration(seconds: 1);
          if (_elapsed >= _total) {
            _fallbackTimer?.cancel();
            _playing = false;
            _onSessionFinished();
          }
        });
      });
      setState(() => _playing = true);
    }
  }

  Future<void> _onSessionFinished() async {
    if (_completed) return;
    _completed = true;
    _fallbackTimer?.cancel();
    await _player.stop();

    final before = ref.read(quranCurriculumProvider).progress;
    final wasLastSession = before.currentSessionIndex >= quranSessionsPerKhatmah;
    final finishedKhatmah = before.currentKhatmahIndex;

    await ref.read(quranCurriculumProvider.notifier).completeCurrentSession();
    if (!mounted) return;

    final after = ref.read(quranCurriculumProvider).progress;
    final khatmahJustCompleted = wasLastSession;

    if (khatmahJustCompleted) {
      context.go(
        AppRoutes.quranCelebrationPath(finishedKhatmah),
      );
      return;
    }

    final canContinue = ref.read(quranCurriculumProvider.notifier).canStartAnotherSessionToday();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        title: const Text('أحسنتِ!'),
        content: Text(
          canContinue
              ? 'أكملت جلسة الاستماع (${after.sessionsCompletedToday} من ${ref.read(quranCurriculumProvider).dailyRepetitions} اليوم).'
              : 'أكملت جلسات اليوم. بارك الله فيكم!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quranCurriculumProvider);
    final theme = Theme.of(context);
    final progress = _total.inMilliseconds == 0
        ? 0.0
        : (_elapsed.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
    final daily = state.dailyRepetitions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: state.currentSession.title,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            TactileClayCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Text(
                    'الجلسة ${state.progress.sessionsCompletedToday + 1} من $daily اليوم',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.currentSession.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TactileClayProgress(value: progress),
                ],
              ),
            ),
            const SizedBox(height: 20),
            QuranFloatingHero(playing: _playing),
            const SizedBox(height: 12),
            TactileClayCard(
              color: AppColors.primaryContainer.withValues(alpha: 0.25),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/byanour-baby.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Symbols.child_care,
                        size: 40,
                        color: AppColors.primary,
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
                          'نستمع معاً',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          state.currentKhatmah.reciter.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ClayPlayOrb(
              playing: _playing,
              enabled: !_completed,
              onTap: _togglePlay,
            ),
            const SizedBox(height: 16),
            Text(
              '${_format(_elapsed)} / ${_format(_total)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (_audioLoaded) ...[
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: progress,
                  onChanged: _completed
                      ? null
                      : (v) => _seekTo(Duration(
                            milliseconds: (_total.inMilliseconds * v).round(),
                          )),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SkipChip(
                    icon: Symbols.replay_10,
                    onTap: _completed ? null : () => _skipBy(const Duration(seconds: -10)),
                  ),
                  const SizedBox(width: 24),
                  _SkipChip(
                    icon: Symbols.forward_10,
                    onTap: _completed ? null : () => _skipBy(const Duration(seconds: 10)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            TactileClayButton(
              label: _playing ? 'إيقاف مؤقت' : 'تشغيل',
              icon: _playing ? Symbols.pause : Symbols.play_arrow,
              onPressed: _completed ? null : _togglePlay,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClayPlayOrb extends StatefulWidget {
  const _ClayPlayOrb({
    required this.playing,
    required this.enabled,
    required this.onTap,
  });

  final bool playing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_ClayPlayOrb> createState() => _ClayPlayOrbState();
}

class _ClayPlayOrbState extends State<_ClayPlayOrb> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 96,
        height: 96,
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDim,
              offset: Offset(0, _pressed ? 2 : 6),
            ),
          ],
        ),
        child: Icon(
          widget.playing ? Symbols.pause : Symbols.play_arrow,
          color: AppColors.onPrimary,
          size: 48,
          fill: 1,
        ),
      ),
    );
  }
}

class _SkipChip extends StatelessWidget {
  const _SkipChip({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
      ),
    );
  }
}
