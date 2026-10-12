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

  @override
  Future<AiChatState> build() async {
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
    state = const AsyncData(AiChatState());
  }

  /// Returns false when the question was not answered (so the screen can restore the text).
  Future<bool> send(String text, {AiMealRequest? meal}) async {
    final question = text.trim();
    final current = state.valueOrNull ?? const AiChatState();
    if (question.length < 2 || current.sending) return false;

    final pending = AiMessage.pendingUser(question);
    state = AsyncData(current.copyWith(
      messages: [...current.messages, pending],
      sending: true,
      clearNotice: true,
    ));

    final result = await _repo.ask(
      question: question,
      conversationId: current.conversationId,
      ageRangeIndex: ref.read(prefsServiceProvider).getBabyAgeRangeIndex(),
      meal: meal,
    );

    final now = state.valueOrNull ?? current;
    final reply = result.message;
    if ((result.status == AiStatus.ok || result.status == AiStatus.emergency) && reply != null) {
      state = AsyncData(now.copyWith(
        conversationId: result.conversationId,
        messages: [...now.messages, reply],
        sending: false,
      ));
      return true;
    }

    state = AsyncData(now.copyWith(
      conversationId: result.conversationId,
      messages: [
        for (final m in now.messages)
          if (m.id != pending.id) m,
      ],
      sending: false,
      notice: aiStatusMessage(result.status),
    ));
    return false;
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
