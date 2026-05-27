import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_session_provider.dart';
import '../data/community_faq_repository.dart';
import '../data/community_feedback_repository.dart';
import '../domain/community_faq_data.dart';
import '../domain/community_feedback_models.dart';

final communityFeedbackRepositoryProvider = Provider<CommunityFeedbackRepository>((ref) {
  return const CommunityFeedbackRepository();
});

final communityFaqRepositoryProvider = Provider<CommunityFaqRepository>((ref) {
  return const CommunityFaqRepository();
});

final communityFaqItemsProvider = FutureProvider<List<CommunityFaqItem>>((ref) {
  return ref.watch(communityFaqRepositoryProvider).loadItems();
});

final myCommunityFeedbackProvider =
    FutureProvider.family<List<CommunityFeedbackTicket>, CommunityFeedbackKind>(
  (ref, kind) async {
    final user = ref.watch(authSessionProvider).valueOrNull?.user;
    if (user == null) return [];

    final kindFilter =
        kind == CommunityFeedbackKind.complaint ? 'complaint' : 'suggestion';

    return ref.read(communityFeedbackRepositoryProvider).fetchMine(
          userId: user.id,
          kind: kindFilter,
        );
  },
);
