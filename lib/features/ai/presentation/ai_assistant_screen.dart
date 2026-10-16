import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'widgets/ai_orb.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../community/presentation/widgets/club_shared.dart';
import '../../support/presentation/consultations_screen.dart';
import '../application/ai_providers.dart';
import '../application/ai_voice.dart';
import '../data/ai_models.dart';
import 'widgets/ai_markdown.dart';
import 'widgets/ai_shared.dart';
import 'widgets/ai_tool_panels.dart';

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

/// «مساعدة بيانور» — chat with structured, referenced answers. Every AI tool
/// (plan, growth, meals…) lives inside it; outside there's only the launcher.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key, this.initialQuestion, this.popup = false});

  final String? initialQuestion;

  /// Shown as the floating window from the home launcher (no Scaffold, no safe-area padding).
  final bool popup;

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _voice = AiVoice();
  bool _listening = false;
  String? _speakingId;
  AiChatTool? _tool;

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
      m.isMarkdown
          ? m.content
          : [
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

  /// Follows the answer while it streams, unless the mother scrolled up to read.
  void _followStream() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final p = _scroll.position;
      if (p.maxScrollExtent - p.pixels < 160) _scroll.jumpTo(p.maxScrollExtent);
    });
  }

  Future<void> _copy(AiMessage m, String? babyName) async {
    await Clipboard.setData(ClipboardData(text: withBabyName(m.content, babyName)));
    if (mounted) showClubSnack(context, 'اتنسخ الرد');
  }

  /// Asks the question before [m] again for a fresh answer.
  void _regenerate(List<AiMessage> messages, AiMessage m) {
    final index = messages.indexOf(m);
    for (var i = index - 1; i >= 0; i--) {
      if (messages[i].isUser) {
        _send(messages[i].content);
        return;
      }
    }
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

  Future<void> _sendMeal(AiMealRequest meal) async {
    final text = [
      'وجبة النهارده',
      if (meal.ingredients.isNotEmpty) 'الموجود عندي: ${meal.ingredients}',
      if (meal.allergies.isNotEmpty) 'عنده حساسية من: ${meal.allergies.join('، ')}',
    ].join('\n');
    _scrollToEnd();
    await ref.read(aiChatProvider.notifier).send(text, meal: meal);
    _scrollToEnd();
  }

  void _close() {
    if (_tool != null) {
      setState(() => _tool = null);
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _openTool(AiChatTool tool) {
    if (tool == AiChatTool.plan) {
      final plan = ref.read(aiDailyPlanProvider);
      if (plan.valueOrNull?.plan == null && !plan.isLoading) ref.invalidate(aiDailyPlanProvider);
    }
    setState(() => _tool = tool);
  }

  List<_AiTool> _tools() {
    return [
      _AiTool('خطة النهارده', () => _openTool(AiChatTool.plan)),
      _AiTool('نموه', () => _openTool(AiChatTool.growth)),
      _AiTool('وجبة النهارده', () => _openTool(AiChatTool.meal)),
      _AiTool('طفلي بيعيط', () => _send('طفلي بيعيط ومش عارفة ليه، أعمل إيه؟')),
      _AiTool('تطعيمات ومهارات', () => _openTool(AiChatTool.vaccines)),
      _AiTool('لون البراز', () => _openTool(AiChatTool.stool)),
    ];
  }

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

  Widget _emergencyFor(AiMessage m) {
    final e = m.emergency!;
    return _EmergencyCard(
      title: e['title']?.toString() ?? 'ده موقف طارئ',
      message: e['message']?.toString() ?? '',
      steps: [for (final s in (e['steps'] as List? ?? const [])) s.toString()],
      onConsult: _openConsultations,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(aiChatProvider);
    final babyName = ref.watch(prefsServiceProvider).getBabyName();
    final state = chat.valueOrNull;
    final messages = state?.messages ?? const <AiMessage>[];
    final sending = state?.sending == true;
    final lastAssistantId = messages.lastWhere(
      (m) => !m.isUser && !m.isEmergency,
      orElse: () => AiMessage.pendingUser(''),
    ).id;
    ref.listen(aiChatProvider, (prev, next) {
      final before = prev?.valueOrNull?.messages;
      final after = next.valueOrNull?.messages;
      if (after != null && after.isNotEmpty && after.last.isStreaming && after.last != before?.lastOrNull) {
        _followStream();
      }
    });

    final tools = _tools();
    final padding = MediaQuery.paddingOf(context);
    final toolOpen = _tool != null;

    final panel = Column(
      children: [
        if (!toolOpen)
          _ChatHeader(
            topInset: widget.popup ? 0 : padding.top,
            onClose: _close,
            onNewChat: messages.isEmpty || sending ? null : () => ref.read(aiChatProvider.notifier).newConversation(),
          ),
        Expanded(
          child: toolOpen
              ? AiToolPanel(
                  tool: _tool!,
                  onClose: () => setState(() => _tool = null),
                  onMealReady: _sendMeal,
                )
              : DecoratedBox(
                  decoration: const BoxDecoration(gradient: AiSiteColors.messageGradient),
                  child: chat.isLoading && state == null
                      ? const Center(child: CircularProgressIndicator(color: AiSiteColors.teal))
                      : messages.isEmpty
                          ? const _EmptyThread()
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              itemCount: messages.length,
                              itemBuilder: (context, i) {
                                final m = messages[i];
                                if (m.isUser) return _UserBubble(text: m.content);
                                if (m.isEmergency) {
                                  return _EmergencyCard(
                                    title: m.emergencyTitle,
                                    message: m.content,
                                    steps: m.emergencySteps,
                                    onConsult: _openConsultations,
                                  );
                                }
                                if (m.isStreaming && m.content.isEmpty) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (m.emergency != null) _emergencyFor(m),
                                      const _TypingBubble(),
                                    ],
                                  );
                                }
                                if (m.isMarkdown) {
                                  final isLast = m.id == lastAssistantId;
                                  return _ChatAnswer(
                                    message: m,
                                    babyName: babyName,
                                    rating: state?.ratings[m.id],
                                    emergency: m.emergency != null ? _emergencyFor(m) : null,
                                    showFollowups: isLast && !sending,
                                    onFollowup: _send,
                                    onRate: (r) => _rate(m, r),
                                    speaking: _speakingId == m.id,
                                    onSpeak: () => _toggleSpeak(m, babyName),
                                    onCopy: () => _copy(m, babyName),
                                    onRegenerate: isLast && !sending ? () => _regenerate(messages, m) : null,
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
        ),
        if (!toolOpen && state?.notice != null)
          Container(
            width: double.infinity,
            color: AppColors.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              state!.notice!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        if (!toolOpen) ...[
          _PinnedBar(
            questions: _starterQuestions,
            tools: tools,
            enabled: !sending,
            onQuestion: _send,
          ),
          _InputBar(
            controller: _input,
            sending: sending,
            listening: _listening,
            bottomInset: widget.popup ? 0 : padding.bottom,
            onSend: () => _send(),
            onStop: () => ref.read(aiChatProvider.notifier).stop(),
            onMic: _toggleMic,
          ),
        ],
      ],
    );

    if (widget.popup) return Material(color: AiSiteColors.cream50, child: panel);
    return Scaffold(backgroundColor: AiSiteColors.cream50, body: panel);
  }
}

class _AiTool {
  const _AiTool(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;
}

/// The «مساعدة بيانور» bar: mascot, online status, new chat and close.
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.topInset, required this.onClose, required this.onNewChat});

  final double topInset;
  final VoidCallback onClose;
  final VoidCallback? onNewChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14 + topInset, 12, 14),
      decoration: const BoxDecoration(gradient: AiSiteColors.headerGradient),
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _StarsPainter()))),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AiSiteColors.cream100.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const BayanourFace(size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'مساعد بيانور',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AiSiteColors.cream50,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AiSiteColors.mint300, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'متصل الآن • يردّ في ثوانٍ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AiSiteColors.mint200.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onNewChat != null) ...[
                _HeaderButton(icon: Symbols.add_comment, tooltip: 'محادثة جديدة', onTap: onNewChat!),
                const SizedBox(width: 6),
              ],
              _HeaderButton(icon: Symbols.close, tooltip: 'إغلاق المحادثة', onTap: onClose),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(side: BorderSide(color: AiSiteColors.cream100.withValues(alpha: 0.15))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 16, color: AiSiteColors.cream100.withValues(alpha: 0.8)),
          ),
        ),
      ),
    );
  }
}

/// Soft four-point stars behind the header.
class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  static const _spots = [
    (0.10, 0.25, 9.0),
    (0.28, 0.78, 6.0),
    (0.47, 0.22, 7.0),
    (0.64, 0.72, 10.0),
    (0.82, 0.30, 6.0),
    (0.95, 0.82, 8.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AiSiteColors.cream100.withValues(alpha: 0.16);
    for (final (x, y, r) in _spots) {
      final c = Offset(size.width * x, size.height * y);
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _botBubbleRadius = BorderRadiusDirectional.only(
  topStart: Radius.circular(18),
  topEnd: Radius.circular(18),
  bottomEnd: Radius.circular(18),
  bottomStart: Radius.circular(4),
);

BoxDecoration _botBubbleDecoration() => BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: _botBubbleRadius,
      border: Border.all(color: AppColors.outlineVariant),
      boxShadow: [
        BoxShadow(color: AppColors.onPrimaryFixed.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
      ],
    );

/// Empty thread, matching the landing card before the first message.
class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          'إجابات تعليمية من مراجع علمية (WHO، AAP، CDC، NHS) ومش بديل عن الطبيب.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AiSiteColors.ink800.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

/// Tools stay visible first; starter questions sit in a second scrollable row.
class _PinnedBar extends StatelessWidget {
  const _PinnedBar({
    required this.questions,
    required this.tools,
    required this.enabled,
    required this.onQuestion,
  });

  final List<String> questions;
  final List<_AiTool> tools;
  final bool enabled;
  final ValueChanged<String> onQuestion;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AiSiteColors.cream50,
        border: Border(top: BorderSide(color: AiSiteColors.ink900.withValues(alpha: 0.08))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tool in tools)
                  _SiteChip(label: tool.label, onTap: enabled ? tool.onTap : null),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _SiteChip(
                  label: questions[i],
                  onTap: enabled ? () => onQuestion(questions[i]) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SiteChip extends StatelessWidget {
  const _SiteChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AiSiteColors.teal.withValues(alpha: 0.08),
      shape: StadiumBorder(side: BorderSide(color: AiSiteColors.teal.withValues(alpha: 0.25))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(color: AiSiteColors.teal, fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
        ),
      ),
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
        margin: const EdgeInsetsDirectional.only(bottom: 12, start: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AiSiteColors.teal.withValues(alpha: 0.12),
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(18),
            topEnd: Radius.circular(18),
            bottomStart: Radius.circular(18),
            bottomEnd: Radius.circular(4),
          ),
          border: Border.all(color: AiSiteColors.teal.withValues(alpha: 0.25)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AiSiteColors.ink900, height: 1.6),
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

/// ChatGPT-style answer: full-width markdown that streams in, then actions and follow-ups.
class _ChatAnswer extends StatelessWidget {
  const _ChatAnswer({
    required this.message,
    required this.babyName,
    required this.rating,
    required this.emergency,
    required this.showFollowups,
    required this.onFollowup,
    required this.onRate,
    required this.speaking,
    required this.onSpeak,
    required this.onCopy,
    required this.onRegenerate,
  });

  final AiMessage message;
  final String? babyName;
  final int? rating;
  final Widget? emergency;
  final bool showFollowups;
  final ValueChanged<String> onFollowup;
  final ValueChanged<int> onRate;
  final bool speaking;
  final VoidCallback onSpeak;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streaming = message.isStreaming;
    final saved = !streaming && !message.isLocal;
    final cut = message.payload['cut'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (emergency != null) emergency!,
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: _botBubbleDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectionArea(
                  child: AiMarkdown(
                    text: withBabyName(message.content, babyName),
                    trailing: streaming ? const _StreamCursor() : null,
                  ),
                ),
                if (cut)
                  Text(
                    'الرد اتوقف قبل ما يكمل',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                if (message.notes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: AppRadius.brMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Symbols.health_and_safety, size: 18, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text('تنبيهات أمان', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final n in message.notes)
                          Text('• $n', style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!streaming && message.sources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AiSourcesRow(sources: message.sources),
            ),
          if (!streaming)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  _ActionIcon(icon: Symbols.content_copy, tooltip: 'نسخ', onTap: onCopy),
                  _ActionIcon(
                    icon: speaking ? Symbols.stop_circle : Symbols.volume_up,
                    tooltip: speaking ? 'إيقاف' : 'اسمعي الرد',
                    onTap: onSpeak,
                    active: speaking,
                  ),
                  if (onRegenerate != null)
                    _ActionIcon(icon: Symbols.refresh, tooltip: 'جاوبيني تاني', onTap: onRegenerate!),
                  if (saved) ...[
                    _ActionIcon(
                      icon: Symbols.thumb_up,
                      tooltip: 'مفيد',
                      onTap: rating == 1 ? null : () => onRate(1),
                      active: rating == 1,
                    ),
                    _ActionIcon(
                      icon: Symbols.thumb_down,
                      tooltip: 'الرد مش مظبوط',
                      onTap: rating == -1 ? null : () => onRate(-1),
                      active: rating == -1,
                      activeColor: AppColors.error,
                    ),
                  ],
                ],
              ),
            ),
          if (showFollowups && message.followups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in message.followups)
                    _SiteChip(
                      label: withBabyName(f, babyName),
                      onTap: () => onFollowup(withBabyName(f, babyName)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.activeColor = AppColors.primary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap == null ? null : () {
        HapticFeedback.selectionClick();
        onTap!();
      },
      icon: Icon(icon, size: 20, fill: active ? 1 : 0, color: active ? activeColor : AppColors.onSurfaceVariant),
    );
  }
}

class _StreamCursor extends StatefulWidget {
  const _StreamCursor();

  @override
  State<_StreamCursor> createState() => _StreamCursorState();
}

class _StreamCursorState extends State<_StreamCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        margin: const EdgeInsetsDirectional.only(start: 3),
        width: 9,
        height: 9,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
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
  const _EmergencyCard({required this.title, required this.message, required this.steps, required this.onConsult});

  final String title;
  final String message;
  final List<String> steps;
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
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(color: AppColors.onError, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (message.isNotEmpty) Text(message, style: textStyle),
          const SizedBox(height: 8),
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $s', style: textStyle),
            ),
          const SizedBox(height: 12),
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
        decoration: _botBubbleDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'بيانور بتفكر',
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
    required this.bottomInset,
    required this.onSend,
    required this.onStop,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool sending;
  final bool listening;
  final double bottomInset;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: AppRadius.brFull,
      borderSide: BorderSide(color: AiSiteColors.ink900.withValues(alpha: 0.1)),
    );
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
      decoration: BoxDecoration(
        color: AiSiteColors.cream50,
        border: Border(top: BorderSide(color: AiSiteColors.ink900.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: theme.textTheme.bodyMedium?.copyWith(color: AiSiteColors.ink900, fontSize: 12.5),
              cursorColor: AiSiteColors.teal,
              decoration: InputDecoration(
                hintText: listening ? 'بسمعك… اتكلمي' : 'اكتبي سؤالك…',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: AiSiteColors.ink800.withValues(alpha: 0.35),
                  fontSize: 12.5,
                ),
                filled: true,
                fillColor: AiSiteColors.cream100.withValues(alpha: 0.7),
                isDense: true,
                counterText: '',
                prefixIcon: IconButton(
                  tooltip: listening ? 'إيقاف التسجيل' : 'اسألي بصوتك',
                  onPressed: sending ? null : onMic,
                  icon: Icon(
                    listening ? Symbols.stop : Symbols.mic,
                    size: 18,
                    color: listening ? AppColors.error : AiSiteColors.teal,
                  ),
                ),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(borderSide: BorderSide(color: AiSiteColors.teal.withValues(alpha: 0.5))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: sending ? 'إيقاف الرد' : 'إرسال',
            child: GestureDetector(
              onTap: sending ? onStop : onSend,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AiSiteColors.sendGradient),
                child: sending
                    ? const Icon(Symbols.stop, size: 16, color: AiSiteColors.mint300)
                    : const AiSparkleIcon(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
