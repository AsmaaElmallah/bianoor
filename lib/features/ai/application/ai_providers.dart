import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../data/ai_models.dart';
import '../data/ai_repository.dart';

final aiSettingsProvider = FutureProvider.autoDispose<AiSettings>((ref) {
  return ref.watch(aiRepositoryProvider).fetchSettings();
});

/// Cached for the session — the server stores one plan per day anyway.
final aiDailyPlanProvider = FutureProvider<AiPlanResult>((ref) {
  final prefs = ref.watch(prefsServiceProvider);
  return ref.watch(aiRepositoryProvider).fetchTodayPlan(
        ageRangeIndex: prefs.getBabyAgeRangeIndex(),
        lang: prefs.getLanguage() ?? 'ar',
      );
});

class AiChatState {
  const AiChatState({
    this.conversationId,
    this.messages = const [],
    this.sending = false,
    this.notice,
    this.ratings = const {},
  });

  final String? conversationId;
  final List<AiMessage> messages;
  final bool sending;

  /// Limit / busy / error text shown above the input.
  final String? notice;
  final Map<String, int> ratings;

  AiChatState copyWith({
    String? conversationId,
    List<AiMessage>? messages,
    bool? sending,
    String? notice,
    bool clearNotice = false,
    Map<String, int>? ratings,
  }) {
    return AiChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      notice: clearNotice ? null : (notice ?? this.notice),
      ratings: ratings ?? this.ratings,
    );
  }
}

final aiChatProvider = AsyncNotifierProvider.autoDispose<AiChatNotifier, AiChatState>(AiChatNotifier.new);

class AiChatNotifier extends AutoDisposeAsyncNotifier<AiChatState> {
  AiRepository get _repo => ref.read(aiRepositoryProvider);

  StreamSubscription<AiStreamEvent>? _subscription;
  Completer<bool>? _answered;
  String? _pendingId;
  AiMessage? _reply;

  @override
  Future<AiChatState> build() async {
    ref.onDispose(() => _subscription?.cancel());
    final id = await _repo.latestConversationId();
    if (id == null) return const AiChatState();
    final messages = await _repo.fetchMessages(id);
    final ratings = await _repo.fetchMyRatings([
      for (final m in messages)
        if (!m.isUser) m.id,
    ]);
    return AiChatState(conversationId: id, messages: messages, ratings: ratings);
  }

  void newConversation() {
    if (state.valueOrNull?.sending == true) return;
    state = const AsyncData(AiChatState());
  }

  /// Returns false when the question was not answered (so the screen can restore the text).
  Future<bool> send(String text, {AiMealRequest? meal}) async {
    final question = text.trim();
    final current = state.valueOrNull ?? const AiChatState();
    if (question.length < 2 || current.sending) return false;

    final pending = AiMessage.pendingUser(question);
    _pendingId = pending.id;
    _reply = AiMessage.streaming();
    state = AsyncData(current.copyWith(
      messages: [...current.messages, pending, _reply!],
      sending: true,
      clearNotice: true,
    ));

    final answered = _answered = Completer<bool>();
    _subscription = _repo
        .askStream(
          question: question,
          conversationId: current.conversationId,
          ageRangeIndex: ref.read(prefsServiceProvider).getBabyAgeRangeIndex(),
          meal: meal,
        )
        .listen(_onEvent, onDone: () => _finish(_reply?.content.trim().isNotEmpty ?? false));
    return answered.future;
  }

  /// Stops the answer being written; whatever arrived so far stays on screen.
  void stop() {
    if (_subscription == null) return;
    final partial = _reply;
    if (partial == null || partial.content.trim().isEmpty) {
      _removeReply(keepQuestion: true);
      _finish(false);
    } else {
      _showReply(partial.asCut(), sending: false);
      _finish(true);
    }
  }

  void _onEvent(AiStreamEvent event) {
    final reply = _reply;
    if (reply == null) return;
    if (event.conversationId != null) {
      state = AsyncData((state.valueOrNull ?? const AiChatState()).copyWith(conversationId: event.conversationId));
    }
    switch (event.type) {
      case AiStreamEventType.meta:
        if (event.emergency != null) _showReply(reply.copyWith(payload: {...reply.payload, 'emergency': event.emergency}));
      case AiStreamEventType.delta:
        _showReply(reply.copyWith(content: reply.content + event.text));
      case AiStreamEventType.done:
        _showReply(event.message!, sending: false);
        _finish(true);
      case AiStreamEventType.failed:
        final notice = aiStatusText(event.status, event.detail);
        if (reply.content.trim().isNotEmpty) {
          _showReply(reply.asCut(), sending: false, notice: notice);
          _finish(true);
        } else {
          _removeReply(keepQuestion: false, notice: notice);
          _finish(false);
        }
    }
  }

  void _showReply(AiMessage message, {bool sending = true, String? notice}) {
    final placeholderId = _reply?.id;
    _reply = message;
    final now = state.valueOrNull ?? const AiChatState();
    state = AsyncData(now.copyWith(
      messages: [
        for (final m in now.messages)
          if (m.id != placeholderId) m,
        message,
      ],
      sending: sending,
      notice: notice,
    ));
  }

  void _removeReply({required bool keepQuestion, String? notice}) {
    final placeholderId = _reply?.id;
    final now = state.valueOrNull ?? const AiChatState();
    state = AsyncData(now.copyWith(
      messages: [
        for (final m in now.messages)
          if (m.id != placeholderId && (keepQuestion || m.id != _pendingId)) m,
      ],
      sending: false,
      notice: notice,
    ));
  }

  void _finish(bool answered) {
    _subscription?.cancel();
    _subscription = null;
    _reply = null;
    final completer = _answered;
    _answered = null;
    if (completer != null && !completer.isCompleted) completer.complete(answered);
    final now = state.valueOrNull;
    if (now != null && now.sending) state = AsyncData(now.copyWith(sending: false));
  }

  Future<void> rate(String messageId, int rating, {String? reason}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(ratings: {...current.ratings, messageId: rating}));
    try {
      await _repo.rate(messageId, rating, reason: reason);
    } catch (_) {
      final now = state.valueOrNull ?? current;
      state = AsyncData(now.copyWith(ratings: {...now.ratings}..remove(messageId)));
      rethrow;
    }
  }
}
