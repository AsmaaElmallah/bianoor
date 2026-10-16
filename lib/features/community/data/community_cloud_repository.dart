import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions, PostgrestException;

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/community_faq_data.dart';

const clubMediaBucket = 'club-media';

enum ClubSort { newest, popular, unanswered }

class MothersClubCategory {
  const MothersClubCategory({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}

class MothersClubPost {
  const MothersClubPost({
    required this.id,
    required this.title,
    required this.body,
    this.authorId,
    this.authorDisplayName,
    this.categoryId,
    this.groupId,
    this.tag,
    this.publishStatus = 'published',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isAnonymous = false,
    this.isPinned = false,
    this.hasExpertReply = false,
    this.imageUrl,
    this.createdAt,
  });

  factory MothersClubPost.fromRow(Map<String, dynamic> row) => MothersClubPost(
        id: row['id'] as String,
        title: row['title'] as String? ?? '',
        body: row['body'] as String? ?? '',
        authorId: row['author_id'] as String?,
        authorDisplayName: row['author_display_name'] as String?,
        categoryId: row['category_id'] as String?,
        groupId: row['group_id'] as String?,
        tag: row['tag'] as String?,
        publishStatus: row['publish_status'] as String? ?? 'published',
        likesCount: (row['likes_count'] as num?)?.toInt() ?? 0,
        commentsCount: (row['comments_count'] as num?)?.toInt() ?? 0,
        isAnonymous: row['is_anonymous'] == true,
        isPinned: row['is_pinned'] == true,
        hasExpertReply: row['has_expert_reply'] == true,
        imageUrl: _publicImageUrl(row['image_storage_path'] as String?),
        createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      );

  static String? _publicImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    if (!SupabaseBootstrap.isReady) return null;
    return SupabaseBootstrap.client.storage.from(clubMediaBucket).getPublicUrl(path);
  }

  final String? imageUrl;

  static const anonymousName = 'أم من النادي';

  String get displayAuthor {
    if (isAnonymous) return anonymousName;
    final name = authorDisplayName?.trim();
    return name == null || name.isEmpty ? 'أم' : name;
  }

  final bool isAnonymous;
  final bool isPinned;
  final bool hasExpertReply;

  final String id;
  final String title;
  final String body;
  final String? authorId;
  final String? authorDisplayName;
  final String? categoryId;
  final String? groupId;
  final String? tag;
  final String publishStatus;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;

  bool get isPublished => publishStatus == 'published';
  bool get isInReview => publishStatus == 'review' || publishStatus == 'draft';
  bool get isRejected => publishStatus == 'archived';
}

/// A group the admin made (e.g. one per course). Open to every mother;
/// joining only means getting the admin's announcements as push.
class MothersClubGroup {
  const MothersClubGroup({
    required this.id,
    required this.title,
    this.description = '',
    this.iconKey = 'people',
    this.courseId,
    this.infoNote = '',
    this.postsCount = 0,
    this.membersCount = 0,
  });

  factory MothersClubGroup.fromRow(Map<String, dynamic> row) => MothersClubGroup(
        id: row['id'] as String,
        title: row['title'] as String? ?? '',
        description: row['description'] as String? ?? '',
        iconKey: row['icon_key'] as String? ?? 'people',
        courseId: row['course_id'] as String?,
        infoNote: row['info_note'] as String? ?? '',
        postsCount: (row['posts_count'] as num?)?.toInt() ?? 0,
        membersCount: (row['members_count'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final String? courseId;
  final String infoNote;
  final int postsCount;
  final int membersCount;
}

class MothersClubComment {
  const MothersClubComment({
    required this.id,
    required this.postId,
    required this.body,
    this.authorId,
    this.authorDisplayName,
    this.isExpert = false,
    this.createdAt,
  });

  factory MothersClubComment.fromRow(Map<String, dynamic> row) => MothersClubComment(
        id: row['id'] as String,
        postId: row['post_id'] as String,
        body: row['body'] as String? ?? '',
        authorId: row['author_id'] as String?,
        authorDisplayName: row['author_display_name'] as String?,
        isExpert: row['is_expert'] == true,
        createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      );

  final bool isExpert;
  final String id;
  final String postId;
  final String body;
  final String? authorId;
  final String? authorDisplayName;
  final DateTime? createdAt;
}

class ClubActionException implements Exception {
  const ClubActionException(this.message);
  final String message;
  @override
  String toString() => message;
}

final communityCloudRepositoryProvider = Provider<CommunityCloudRepository>((ref) {
  return CommunityCloudRepository();
});

final myCommunityFeedbackProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, kind) {
  return ref
      .watch(communityCloudRepositoryProvider)
      .fetchMyFeedback(kind: kind);
});

final publishedFaqProvider = FutureProvider<List<CommunityFaqItem>>((ref) {
  return ref.watch(communityCloudRepositoryProvider).fetchPublishedFaq();
});

final mothersClubCategoriesProvider =
    FutureProvider<List<MothersClubCategory>>((ref) {
  return ref.watch(communityCloudRepositoryProvider).fetchClubCategories();
});

final mothersClubCommentsProvider =
    FutureProvider.autoDispose.family<List<MothersClubComment>, String>((ref, postId) {
  return ref.watch(communityCloudRepositoryProvider).fetchComments(postId);
});

final mothersClubNotificationsProvider = FutureProvider.autoDispose<List<MothersClubNotification>>((ref) {
  return ref.watch(communityCloudRepositoryProvider).fetchMyNotifications();
});

/// Posts I liked, updated optimistically so the heart reacts instantly.
final clubGroupsProvider = FutureProvider.autoDispose<List<MothersClubGroup>>((ref) {
  return ref.watch(communityCloudRepositoryProvider).fetchGroups();
});

final clubGroupProvider = FutureProvider.autoDispose.family<MothersClubGroup?, String>((ref, groupId) {
  return ref.watch(communityCloudRepositoryProvider).fetchGroup(groupId);
});

final clubGroupPostsProvider =
    FutureProvider.autoDispose.family<List<MothersClubPost>, String>((ref, groupId) {
  return ref.watch(communityCloudRepositoryProvider).fetchGroupPosts(groupId);
});

/// Groups I joined (get the admin's announcements as push), updated optimistically.
final myClubGroupsProvider =
    AsyncNotifierProvider<MyClubGroupsNotifier, Set<String>>(MyClubGroupsNotifier.new);

class MyClubGroupsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.watch(communityCloudRepositoryProvider).fetchMyGroupIds();

  bool isMember(String groupId) => state.valueOrNull?.contains(groupId) ?? false;

  Future<void> toggle(String groupId) async {
    final current = {...?state.valueOrNull};
    final join = !current.contains(groupId);
    state = AsyncData(join ? ({...current, groupId}) : ({...current}..remove(groupId)));
    try {
      await ref.read(communityCloudRepositoryProvider).setGroupMember(groupId, join);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

/// Posts I liked, updated optimistically so the heart reacts instantly.
final mothersClubLikesProvider =
    AsyncNotifierProvider<MothersClubLikesNotifier, Set<String>>(MothersClubLikesNotifier.new);

class MothersClubLikesNotifier extends AsyncNotifier<Set<String>> {
  Set<String> _server = const {};

  @override
  Future<Set<String>> build() async {
    _server = await ref.watch(communityCloudRepositoryProvider).fetchMyLikedPostIds();
    return {..._server};
  }

  bool isLiked(String postId) => state.valueOrNull?.contains(postId) ?? false;

  /// Server count adjusted by likes toggled since the last fetch.
  int countFor(MothersClubPost post) {
    final now = isLiked(post.id) ? 1 : 0;
    final before = _server.contains(post.id) ? 1 : 0;
    return (post.likesCount + now - before).clamp(0, 1 << 30);
  }

  Future<void> toggle(String postId) async {
    final current = {...?state.valueOrNull};
    final like = !current.contains(postId);
    state = AsyncData(like ? ({...current, postId}) : (current..remove(postId)));
    try {
      await ref.read(communityCloudRepositoryProvider).setLiked(postId, like);
    } catch (_) {
      state = AsyncData(like ? (current..remove(postId)) : ({...current, postId}));
      rethrow;
    }
  }
}

class CommunityCloudRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<List<CommunityFaqItem>> fetchPublishedFaq() async {
    if (!await _ready()) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('community_faq')
          .select()
          .eq('publish_status', 'published')
          .order('sort_order');
      return [
        for (final row in List<Map<String, dynamic>>.from(rows as List))
          CommunityFaqItem(
            question: row['question'] as String? ?? '',
            answer: row['answer'] as String? ?? '',
          ),
      ];
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Community] FAQ failed: $e\n$st');
      return [];
    }
  }

  Future<bool> submitFeedback({
    required String kind,
    required String subject,
    required String body,
  }) async {
    if (!await _ready()) return false;
    try {
      final userId = SupabaseBootstrap.client.auth.currentUser?.id;
      await SupabaseBootstrap.client.from('community_feedback').insert({
        'user_id': userId,
        'kind': kind,
        'subject': subject,
        'body': body,
      });
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Community] feedback failed: $e\n$st');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyFeedback({String? kind}) async {
    if (!await _ready()) return [];
    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      var q = SupabaseBootstrap.client
          .from('community_feedback')
          .select()
          .eq('user_id', userId);
      if (kind != null) q = q.eq('kind', kind);
      final rows = await q.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Community] my feedback failed: $e\n$st');
      return [];
    }
  }

  Future<List<MothersClubCategory>> fetchClubCategories() async {
    if (!await _ready()) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('mothers_club_categories')
          .select()
          .eq('publish_status', 'published')
          .order('sort_order');
      return [
        for (final row in List<Map<String, dynamic>>.from(rows as List))
          MothersClubCategory(
            id: row['id'] as String,
            title: (row['label'] ?? row['title']) as String? ?? '',
          ),
      ];
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Community] categories failed: $e\n$st');
      return [];
    }
  }

  String? get currentUserId => SupabaseBootstrap.isReady ? SupabaseBootstrap.client.auth.currentUser?.id : null;

  /// One page of the club feed: published posts (plus my own in-review ones when not searching).
  Future<List<MothersClubPost>> fetchFeed({
    String? ageId,
    ClubSort sort = ClubSort.newest,
    String search = '',
    Set<String>? onlyIds,
    required int offset,
    required int limit,
  }) async {
    if (!await _ready()) return [];
    if (onlyIds != null && onlyIds.isEmpty) return [];
    final userId = currentUserId;
    final term = search.trim().replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();

    var q = SupabaseBootstrap.client.from('mothers_club_posts').select();
    // Group posts stay inside their groups; «المحفوظة» shows saved ones from anywhere.
    if (onlyIds == null) q = q.isFilter('group_id', null);
    if (term.isNotEmpty) {
      // PostgREST takes one top-level `or`, so search shows published posts only.
      q = q.eq('publish_status', 'published').or('title.ilike.*$term*,body.ilike.*$term*');
    } else if (userId == null) {
      q = q.eq('publish_status', 'published');
    } else {
      q = q.or('publish_status.eq.published,author_id.eq.$userId');
    }
    if (ageId != null) q = q.eq('category_id', ageId);
    if (onlyIds != null) q = q.inFilter('id', onlyIds.toList());
    if (sort == ClubSort.unanswered) q = q.eq('comments_count', 0);

    var ordered = q.order('is_pinned', ascending: false);
    if (sort == ClubSort.popular) {
      ordered = ordered.order('likes_count', ascending: false).order('comments_count', ascending: false);
    }
    final rows = await ordered.order('created_at', ascending: false).range(offset, offset + limit - 1);
    return [for (final row in List<Map<String, dynamic>>.from(rows as List)) MothersClubPost.fromRow(row)];
  }

  /// Uploads a picked photo to the mother's own folder and returns its storage path.
  Future<List<MothersClubGroup>> fetchGroups() async {
    if (!await _ready()) return [];
    final rows = await SupabaseBootstrap.client
        .from('mothers_club_groups')
        .select()
        .eq('publish_status', 'published')
        .order('sort_order')
        .order('created_at');
    return [for (final row in List<Map<String, dynamic>>.from(rows as List)) MothersClubGroup.fromRow(row)];
  }

  Future<MothersClubGroup?> fetchGroup(String groupId) async {
    if (!await _ready()) return null;
    final row = await SupabaseBootstrap.client.from('mothers_club_groups').select().eq('id', groupId).maybeSingle();
    return row == null ? null : MothersClubGroup.fromRow(row);
  }

  /// Newest first, pinned on top (admin's info/announcements).
  Future<List<MothersClubPost>> fetchGroupPosts(String groupId) async {
    if (!await _ready()) return [];
    final rows = await SupabaseBootstrap.client
        .from('mothers_club_posts')
        .select()
        .eq('group_id', groupId)
        .eq('publish_status', 'published')
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .limit(60);
    return [for (final row in List<Map<String, dynamic>>.from(rows as List)) MothersClubPost.fromRow(row)];
  }

  Future<Set<String>> fetchMyGroupIds() async {
    if (!await _ready()) return {};
    final userId = currentUserId;
    if (userId == null) return {};
    try {
      final rows = await SupabaseBootstrap.client
          .from('mothers_club_group_members')
          .select('group_id')
          .eq('user_id', userId);
      return {for (final r in List<Map<String, dynamic>>.from(rows as List)) r['group_id'] as String};
    } catch (e) {
      if (kDebugMode) debugPrint('[Community] my groups failed: $e');
      return {};
    }
  }

  Future<void> setGroupMember(String groupId, bool join) async {
    if (!await _ready()) throw const ClubActionException('مفيش اتصال بالإنترنت');
    final userId = _requireUser();
    final table = SupabaseBootstrap.client.from('mothers_club_group_members');
    if (join) {
      await table.upsert({'group_id': groupId, 'user_id': userId}, onConflict: 'group_id,user_id', ignoreDuplicates: true);
    } else {
      await table.delete().eq('group_id', groupId).eq('user_id', userId);
    }
  }

  Future<String> uploadClubImage(Uint8List bytes, {required String extension}) async {
    if (!await _ready()) throw const ClubActionException('مفيش اتصال بالإنترنت');
    final userId = _requireUser();
    final ext = extension.toLowerCase().replaceAll('.', '');
    final safeExt = const {'png', 'webp'}.contains(ext) ? ext : 'jpg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    try {
      await SupabaseBootstrap.client.storage.from(clubMediaBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: safeExt == 'jpg' ? 'image/jpeg' : 'image/$safeExt'),
          );
      return path;
    } catch (e) {
      if (kDebugMode) debugPrint('[Community] image upload failed: $e');
      throw const ClubActionException('تعذّر رفع الصورة — جرّبي صورة أصغر أو من غير صورة');
    }
  }

  Future<Set<String>> fetchMySavedPostIds() async {
    if (!await _ready()) return {};
    final userId = currentUserId;
    if (userId == null) return {};
    try {
      final rows = await SupabaseBootstrap.client.from('mothers_club_saves').select('post_id').eq('user_id', userId);
      return {for (final r in List<Map<String, dynamic>>.from(rows as List)) r['post_id'] as String};
    } catch (e) {
      if (kDebugMode) debugPrint('[Community] saves failed: $e');
      return {};
    }
  }

  Future<void> setSaved(String postId, bool saved) async {
    if (!await _ready()) throw const ClubActionException('مفيش اتصال بالإنترنت');
    final userId = _requireUser();
    final table = SupabaseBootstrap.client.from('mothers_club_saves');
    if (saved) {
      await table.upsert({'post_id': postId, 'user_id': userId}, onConflict: 'user_id,post_id', ignoreDuplicates: true);
    } else {
      await table.delete().eq('post_id', postId).eq('user_id', userId);
    }
  }

  Future<MothersClubPost?> fetchPost(String postId) async {
    if (!await _ready()) return null;
    final row = await SupabaseBootstrap.client.from('mothers_club_posts').select().eq('id', postId).maybeSingle();
    return row == null ? null : MothersClubPost.fromRow(row);
  }

  Future<String> _myDisplayName() async {
    final user = SupabaseBootstrap.client.auth.currentUser;
    try {
      final row = await SupabaseBootstrap.client
          .from('profiles')
          .select('display_name')
          .eq('id', user!.id)
          .maybeSingle();
      final name = (row?['display_name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    final meta = (user?.userMetadata?['display_name'] as String?)?.trim();
    if (meta != null && meta.isNotEmpty) return meta;
    return 'أم';
  }

  String _requireUser() {
    final id = currentUserId;
    if (id == null) throw const ClubActionException('سجّلي دخولك الأول عشان تشاركي في النادي');
    return id;
  }

  /// Sends a question for admin review (it shows to others after approval).
  /// General-feed questions go to admin review; group posts publish right away.
  Future<void> createPost({
    required String title,
    required String body,
    String? categoryId,
    String? groupId,
    bool anonymous = false,
    String? imagePath,
  }) async {
    if (!await _ready()) throw const ClubActionException('مفيش اتصال بالإنترنت');
    final userId = _requireUser();
    try {
      await SupabaseBootstrap.client.from('mothers_club_posts').insert({
        'author_id': userId,
        // The real name is never stored on an anonymous post.
        'author_display_name': anonymous ? MothersClubPost.anonymousName : await _myDisplayName(),
        if (anonymous) 'is_anonymous': true,
        if (imagePath != null) 'image_storage_path': imagePath,
        if (groupId == null) 'category_id': categoryId,
        if (groupId != null) 'group_id': groupId,
        'title': title.trim(),
        'body': body.trim(),
        'publish_status': groupId == null ? 'review' : 'published',
      });
    } on PostgrestException catch (e) {
      if (kDebugMode) debugPrint('[Community] create post failed: ${e.message}');
      throw ClubActionException(
        e.code == '42501' ? 'كتبتي أسئلة كتير الساعة دي، جرّبي بعد شوية' : 'تعذّر إرسال السؤال، حاولي تاني',
      );
    }
  }

  Future<void> deletePost(String postId) async {
    if (!await _ready()) throw const ClubActionException('مفيش اتصال بالإنترنت');
    _requireUser();
    await SupabaseBootstrap.client.from('mothers_club_posts').delete().eq('id', postId);
  }

  Future<Set<String>> fetchMyLikedPostIds() async {
    if (!await _ready()) return {};
    final userId = currentUserId;
    if (userId == null) return {};
    try {
      final rows = await SupabaseBootstrap.client.from('mothers_club_likes').select('post_id').eq('user_id', userId);
      return {for (final r in List<Map<String, dynamic>>.from(rows as List)) r['post_id'] as String};
    } catch (e) {
      if (kDebugMode) debugPrint('[Community] likes failed: $e');
      return {};
    }
  }

  Future<void> setLiked(String postId, bool liked) async {
    if (!await _ready()) throw const ClubActionException('مفيش اتصال بالإنترنت');
    final userId = _requireUser();
    final table = SupabaseBootstrap.client.from('mothers_club_likes');
    if (liked) {
      await table.upsert({'post_id': postId, 'user_id': userId}, onConflict: 'post_id,user_id', ignoreDuplicates: true);
    } else {
      await table.delete().eq('post_id', postId).eq('user_id', userId);
    }
  }

  Future<List<MothersClubComment>> fetchComments(String postId) async {
    if (!await _ready()) return [];
    final rows = await SupabaseBootstrap.client
        .from('mothers_club_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at');
    final all = [for (final r in List<Map<String, dynamic>>.from(rows as List)) MothersClubComment.fromRow(r)];
    return [...all.where((c) => c.isExpert), ...all.where((c) => !c.isExpert)];
  }

  Future<void> addComment(String postId, String body) async {
    if (!await _ready()) throw const ClubActionException('مفيش اتصال بالإنترنت');
    final userId = _requireUser();
    try {
      await SupabaseBootstrap.client.from('mothers_club_comments').insert({
        'post_id': postId,
        'author_id': userId,
        'author_display_name': await _myDisplayName(),
        'body': body.trim(),
      });
    } on PostgrestException catch (e) {
      if (kDebugMode) debugPrint('[Community] comment failed: ${e.message}');
      throw ClubActionException(
        e.code == '42501' ? 'ردود كتير الساعة دي، جرّبي بعد شوية' : 'تعذّر إرسال الرد، حاولي تاني',
      );
    }
  }

  Future<void> deleteComment(String commentId) async {
    if (!await _ready()) throw const ClubActionException('مفيش اتصال بالإنترنت');
    await SupabaseBootstrap.client.from('mothers_club_comments').delete().eq('id', commentId);
  }

  Future<void> report({String? postId, String? commentId, required String reason}) async {
    if (!await _ready()) throw const ClubActionException('مفيش اتصال بالإنترنت');
    final userId = _requireUser();
    try {
      await SupabaseBootstrap.client.from('mothers_club_reports').insert({
        'reporter_id': userId,
        if (postId != null) 'post_id': postId,
        if (commentId != null) 'comment_id': commentId,
        'reason': reason,
      });
    } on PostgrestException catch (e) {
      if (kDebugMode) debugPrint('[Community] report failed: ${e.message}');
      throw const ClubActionException('تعذّر إرسال البلاغ، حاولي تاني');
    }
  }

  Future<List<MothersClubNotification>> fetchMyNotifications() async {
    if (!await _ready()) return [];
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('mothers_club_notifications')
          .select('id, post_id, kind, actor_name, is_read, created_at, mothers_club_posts(title)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);
      return [
        for (final r in List<Map<String, dynamic>>.from(rows as List)) MothersClubNotification.fromRow(r),
      ];
    } catch (e) {
      if (kDebugMode) debugPrint('[Community] notifications failed: $e');
      return [];
    }
  }

  Future<void> markNotificationsRead(Iterable<String> ids) async {
    if (ids.isEmpty || !await _ready()) return;
    try {
      await SupabaseBootstrap.client
          .from('mothers_club_notifications')
          .update({'is_read': true})
          .inFilter('id', ids.toList());
    } catch (e) {
      if (kDebugMode) debugPrint('[Community] mark read failed: $e');
    }
  }
}

class MothersClubNotification {
  const MothersClubNotification({
    required this.id,
    required this.postId,
    required this.kind,
    required this.isRead,
    this.actorName,
    this.postTitle,
    this.createdAt,
  });

  factory MothersClubNotification.fromRow(Map<String, dynamic> row) {
    final post = row['mothers_club_posts'];
    return MothersClubNotification(
      id: row['id'] as String,
      postId: row['post_id'] as String,
      kind: row['kind'] as String? ?? 'reply',
      isRead: row['is_read'] == true,
      actorName: row['actor_name'] as String?,
      postTitle: post is Map ? post['title'] as String? : null,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }

  final String id;
  final String postId;
  final String kind;
  final bool isRead;
  final String? actorName;
  final String? postTitle;
  final DateTime? createdAt;

  String get message {
    final title = postTitle == null ? 'سؤالك' : '«$postTitle»';
    return switch (kind) {
      'expert_reply' => 'الأخصائية ردّت على $title ✓',
      'approved' => 'سؤالك $title اتنشر للأمهات 🎉',
      _ => '${actorName?.isNotEmpty == true ? actorName : 'أم'} ردّت على $title',
    };
  }
}
