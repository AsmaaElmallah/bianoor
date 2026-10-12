import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../community/presentation/widgets/club_shared.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../support/presentation/consultations_screen.dart';
import '../application/ai_providers.dart';
import '../application/ai_voice.dart';
import '../data/ai_models.dart';
import 'widgets/ai_chat_extras.dart';
import 'widgets/ai_shared.dart';

const _starterQuestions = [
  'طفلي مش بينام كويس بالليل، أعمل إيه؟',
  'إيه الأكل المناسب لسنه؟',
  'إيه المهارات المفروض يعملها دلوقتي؟',
  'لعبة تنمّي تركيزه النهارده',
];

const _badReasons = [
  'معلومة غلط',
  'مش مناسبة لسن طفلي',
  'مش واضحة',
  'مش مفيدة',
  'سبب تاني',
];

/// «مساعدة بيانور» — chat with structured, referenced answers.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key, this.initialQuestion});

  final String? initialQuestion;

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _voice = AiVoice();
  bool _listening = false;
  bool _pinHidden = false;
  String? _speakingId;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuestion?.trim();
    if (q != null && q.isNotEmpty) _input.text = q;
  }

  @override
  void dispose() {
    _voice.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _voice.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
      _speakingId = null;
    });
    final ok = await _voice.startListening(
      onText: (text) {
        if (!mounted) return;
        _input.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!ok && mounted) {
      setState(() => _listening = false);
      showClubSnack(context, 'المايك مش متاح — اسمحي للتطبيق باستخدام المايك من الإعدادات');
    }
  }

  Future<void> _toggleSpeak(AiMessage m, String? babyName) async {
    if (_speakingId == m.id) {
      await _voice.stopSpeaking();
      if (mounted) setState(() => _speakingId = null);
      return;
    }
    final activity = m.activity;
    final text = withBabyName(
      [
        m.summary,
        if (activity != null) 'جربي النهارده: ${activity.title}. ${activity.steps.join('. ')}',
        if (m.seeDoctorWhen.isNotEmpty) 'إمتى تروحي للدكتور: ${m.seeDoctorWhen}',
      ].join('. '),
      babyName,
    );
    setState(() => _speakingId = m.id);
    await _voice.speak(text, onDone: () {
      if (mounted && _speakingId == m.id) setState(() => _speakingId = null);
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.length < 2) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    _scrollToEnd();
    final ok = await ref.read(aiChatProvider.notifier).send(text);
    if (!mounted) return;
    if (!ok && _input.text.isEmpty) _input.text = text;
    _scrollToEnd();
  }

  Future<void> _askMeal() async {
    final meal = await showAiMealSheet(
      context,
      ageRangeIndex: ref.read(prefsServiceProvider).getBabyAgeRangeIndex(),
    );
    if (meal == null || !mounted) return;
    final text = [
      'وجبة النهارده 🍲',
      if (meal.ingredients.isNotEmpty) 'الموجود عندي: ${meal.ingredients}',
      if (meal.allergies.isNotEmpty) 'عنده حساسية من: ${meal.allergies.join('، ')}',
    ].join('\n');
    _scrollToEnd();
    await ref.read(aiChatProvider.notifier).send(text, meal: meal);
    _scrollToEnd();
  }

  List<AiShortcut> get _shortcuts => [
        AiShortcut(Symbols.monitoring, 'تابعي نموه', () => context.push(AppRoutes.growth)),
        AiShortcut(Symbols.restaurant, 'وجبة النهارده', _askMeal),
        AiShortcut(Symbols.sentiment_stressed, 'طفلي بيعيط', () => _send('طفلي بيعيط ومش عارفة ليه، أعمل إيه؟')),
        AiShortcut(Symbols.vaccines, 'إمتى؟ (تطعيم ومهارات)', () => context.push(AppRoutes.timeline)),
        AiShortcut(Symbols.palette, 'لون البراز', () => context.push(AppRoutes.stoolColors)),
        AiShortcut(Symbols.event_note, 'خطة النهارده', () => context.push(AppRoutes.dailyPlan)),
      ];

  Future<void> _rate(AiMessage m, int rating) async {
    String? reason;
    if (rating < 0) {
      reason = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        backgroundColor: AppColors.surface,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'إيه اللي مش مظبوط في الرد؟',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              for (final r in _badReasons)
                ListTile(
                  leading: const Icon(Symbols.thumb_down, color: AppColors.error),
                  title: Text(r),
                  onTap: () => Navigator.pop(ctx, r),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (reason == null) return;
    }
    try {
      await ref.read(aiChatProvider.notifier).rate(m.id, rating, reason: reason);
      if (mounted) {
        showClubSnack(context, rating > 0 ? 'شكراً 💛' : 'شكراً، فريق بيانور هيراجع الرد ده');
      }
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر حفظ التقييم');
    }
  }

  void _openConsultations() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ConsultationsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(aiChatProvider);
    final babyName = ref.watch(prefsServiceProvider).getBabyName();
    final emergencyPhone = ref.watch(aiSettingsProvider).valueOrNull?.emergencyPhone ?? '';
    final state = chat.valueOrNull;
    final messages = state?.messages ?? const <AiMessage>[];
    final lastAssistantId = messages.lastWhere(
      (m) => !m.isUser && !m.isEmergency,
      orElse: () => AiMessage.pendingUser(''),
    ).id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: 'مساعدة بيانور', onBack: () => Navigator.of(context).pop()),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      const Expanded(child: AiDisclaimer()),
                      if (messages.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'محادثة جديدة',
                          onPressed: state?.sending == true
                              ? null
                              : () => ref.read(aiChatProvider.notifier).newConversation(),
                          icon: const Icon(Symbols.add_comment),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_pinHidden)
                  AiPinnedTip(
                    babyName: babyName,
                    onAsk: (q) {
                      setState(() => _pinHidden = true);
                      _send(q);
                    },
                    onClose: () => setState(() => _pinHidden = true),
                  ),
                Expanded(
                  child: chat.isLoading && state == null
                      ? const Center(child: CircularProgressIndicator())
                      : messages.isEmpty
                          ? _EmptyChat(babyName: babyName, onPick: _send)
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              itemCount: messages.length + (state?.sending == true ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i >= messages.length) return const _TypingBubble();
                                final m = messages[i];
                                if (m.isUser) return _UserBubble(text: m.content);
                                if (m.isEmergency) {
                                  return _EmergencyCard(
                                    message: m,
                                    phone: emergencyPhone,
                                    onConsult: _openConsultations,
                                  );
                                }
                                return _AnswerCards(
                                  message: m,
                                  babyName: babyName,
                                  rating: state?.ratings[m.id],
                                  showFollowups: m.id == lastAssistantId && state?.sending != true,
                                  onFollowup: _send,
                                  onRate: (r) => _rate(m, r),
                                  onConsult: _openConsultations,
                                  speaking: _speakingId == m.id,
                                  onSpeak: () => _toggleSpeak(m, babyName),
                                );
                              },
                            ),
                ),
                if (state?.notice != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: AppRadius.brMd),
                    child: Text(
                      state!.notice!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                AiShortcutsRow(shortcuts: _shortcuts, enabled: state?.sending != true),
                _InputBar(
                  controller: _input,
                  sending: state?.sending == true,
                  listening: _listening,
                  onSend: () => _send(),
                  onMic: _toggleMic,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.babyName, required this.onPick});

  final String? babyName;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (babyName ?? '').trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      children: [
        const Center(child: AppLogoAvatar(size: 72, imageAsset: AppAssets.logoBaby)),
        const SizedBox(height: 16),
        Text(
          name.isEmpty ? 'أهلاً بيكي 💛' : 'أهلاً يا ماما $name 💛',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'اسأليني عن النوم، الأكل، المهارات، أو اللعب المناسب لسن طفلك. هرد عليكي من مراجع علمية موثوقة وبلهجتك.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        for (final q in _starterQuestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: () => onPick(q),
              icon: const Icon(Symbols.chat_bubble, size: 18),
              label: Align(alignment: AlignmentDirectional.centerStart, child: Text(q)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                side: const BorderSide(color: AppColors.outline),
                foregroundColor: AppColors.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary, height: 1.5),
        ),
      ),
    );
  }
}

class _AnswerCards extends StatelessWidget {
  const _AnswerCards({
    required this.message,
    required this.babyName,
    required this.rating,
    required this.showFollowups,
    required this.onFollowup,
    required this.onRate,
    required this.onConsult,
    required this.speaking,
    required this.onSpeak,
  });

  final AiMessage message;
  final String? babyName;
  final int? rating;
  final bool showFollowups;
  final ValueChanged<String> onFollowup;
  final ValueChanged<int> onRate;
  final VoidCallback onConsult;
  final bool speaking;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String t(String s) => withBabyName(s, babyName);
    final activity = message.activity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Card(
            color: AppColors.surfaceContainerLowest,
            icon: Symbols.favorite,
            iconColor: AppColors.primary,
            title: 'الخلاصة',
            child: Text(t(message.summary), style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          ),
          if (activity != null)
            _Card(
              color: AppColors.trackExerciseLight,
              icon: Symbols.toys,
              iconColor: AppColors.tertiaryDim,
              title: 'جربي النهارده: ${t(activity.title)}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < activity.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.tertiary,
                            child: Text(
                              '${i + 1}',
                              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onTertiary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(t(activity.steps[i]), style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (message.seeDoctorWhen.isNotEmpty)
            _Card(
              color: AppColors.secondaryContainer,
              icon: Symbols.stethoscope,
              iconColor: AppColors.secondaryDim,
              title: 'إمتى تروحي للدكتور',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t(message.seeDoctorWhen), style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: onConsult,
                      icon: const Icon(Symbols.support_agent, size: 18),
                      label: const Text('احجزي استشارة مع أخصائية بيانور'),
                    ),
                  ),
                ],
              ),
            ),
          if (message.notes.isNotEmpty)
            _Card(
              color: AppColors.primaryContainer,
              icon: Symbols.health_and_safety,
              iconColor: AppColors.primary,
              title: 'تنبيهات أمان',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final n in message.notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $n', style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
                    ),
                ],
              ),
            ),
          if (message.sources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: AiSourcesRow(sources: message.sources),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'توجيه عام — مفيش مرجع في مكتبة بيانور للسؤال ده، فالأفضل تستشيري الأخصائية.',
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          Row(
            children: [
              TextButton.icon(
                onPressed: onSpeak,
                icon: Icon(speaking ? Symbols.stop_circle : Symbols.volume_up, size: 20),
                label: Text(speaking ? 'إيقاف' : 'اسمعي الرد'),
              ),
              const Spacer(),
              Text('مفيد؟', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
              IconButton(
                tooltip: 'مفيد',
                onPressed: rating == 1 ? null : () => onRate(1),
                icon: Icon(
                  Symbols.thumb_up,
                  fill: rating == 1 ? 1 : 0,
                  color: rating == 1 ? AppColors.tertiaryDim : AppColors.outline,
                ),
              ),
              IconButton(
                tooltip: 'النصيحة دي مش دقيقة',
                onPressed: rating == -1 ? null : () => onRate(-1),
                icon: Icon(
                  Symbols.thumb_down,
                  fill: rating == -1 ? 1 : 0,
                  color: rating == -1 ? AppColors.error : AppColors.outline,
                ),
              ),
            ],
          ),
          if (showFollowups && message.followups.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in message.followups)
                  ActionChip(
                    label: Text(t(f)),
                    avatar: const Icon(Symbols.reply, size: 16),
                    backgroundColor: AppColors.surfaceContainerLowest,
                    side: const BorderSide(color: AppColors.outline),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
                    onPressed: () => onFollowup(t(f)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.brLg,
        boxShadow: [
          BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.message, required this.phone, required this.onConsult});

  final AiMessage message;
  final String phone;
  final VoidCallback onConsult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(color: AppColors.onError, height: 1.6);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.errorDim, borderRadius: AppRadius.brLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Symbols.emergency, color: AppColors.onError),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.emergencyTitle,
                  style: theme.textTheme.titleMedium?.copyWith(color: AppColors.onError, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message.content, style: textStyle),
          const SizedBox(height: 8),
          for (final s in message.emergencySteps)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $s', style: textStyle),
            ),
          const SizedBox(height: 12),
          if (phone.isNotEmpty)
            FilledButton.icon(
              onPressed: () => openAiLink(context, 'tel:$phone'),
              icon: const Icon(Symbols.call),
              label: Text('اتصلي بالطوارئ ($phone)'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.onError,
                foregroundColor: AppColors.errorDim,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onConsult,
            icon: const Icon(Symbols.support_agent),
            label: const Text('بعد ما تطمني: احجزي استشارة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onError,
              side: const BorderSide(color: AppColors.onError),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: AppRadius.brLg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'بيانور بتكتب',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 6),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: ((_c.value * 3 - i) % 3) < 1 ? 1 : 0.3,
                        child: const CircleAvatar(radius: 3, backgroundColor: AppColors.primary),
                      ),
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

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.listening,
    required this.onSend,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool sending;
  final bool listening;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: listening ? 'إيقاف التسجيل' : 'اسألي بصوتك',
            onPressed: sending ? null : onMic,
            style: IconButton.styleFrom(
              backgroundColor: listening ? AppColors.error : AppColors.primaryContainer,
            ),
            icon: Icon(
              listening ? Symbols.stop : Symbols.mic,
              color: listening ? AppColors.onError : AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: clubInsetDecoration(),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: listening ? 'بسمعك… اتكلمي' : 'اكتبي أو قولي سؤالك عن طفلك…',
                  hintStyle: AppTextField.hintStyle(theme),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            icon: sending
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : const Icon(Symbols.send, color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}
