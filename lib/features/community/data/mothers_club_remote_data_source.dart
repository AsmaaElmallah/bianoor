import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

class MothersClubRemoteDataSource {
  const MothersClubRemoteDataSource();

  static const _imageBucket = 'club-media';

  Future<Map<String, dynamic>> _enrichPostRow(Map<String, dynamic> row) async {
    final path = row['image_storage_path'] as String?;
    if (path == null || path.isEmpty || !SupabaseBootstrap.isReady) {
      return row;
    }
    try {
      final url = await SupabaseBootstrap.client.storage
          .from(_imageBucket)
          .createSignedUrl(path, 3600);
      return {...row, 'image_url': url};
    } catch (_) {
      return row;
    }
  }

  Future<List<Map<String, dynamic>>> _enrichPosts(List<Map<String, dynamic>> rows) async {
    final out = <Map<String, dynamic>>[];
    for (final row in rows) {
      out.add(await _enrichPostRow(row));
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> fetchPublishedCategories() async {
    if (!SupabaseBootstrap.isEnabled) return [];
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();

    final rows = await SupabaseBootstrap.client
        .from('mothers_club_categories')
        .select()
        .eq('publish_status', 'published')
        .order('sort_order');

    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> fetchPublishedPosts({
    String? categoryId,
    int limit = 15,
    int offset = 0,
  }) async {
    if (!SupabaseBootstrap.isEnabled) return [];
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();

    var builder = SupabaseBootstrap.client
        .from('mothers_club_posts')
        .select()
        .eq('publish_status', 'published');

    if (categoryId != null && categoryId.isNotEmpty) {
      builder = builder.eq('category_id', categoryId);
    }

    final rows = await builder
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return _enrichPosts(List<Map<String, dynamic>>.from(rows as List));
  }

  Future<Map<String, dynamic>?> fetchPostById(String postId) async {
    if (!SupabaseBootstrap.isEnabled) return null;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();

    final row = await SupabaseBootstrap.client
        .from('mothers_club_posts')
        .select()
        .eq('id', postId)
        .eq('publish_status', 'published')
        .maybeSingle();

    if (row == null) return null;
    return _enrichPostRow(Map<String, dynamic>.from(row));
  }

  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    if (!SupabaseBootstrap.isEnabled) return [];
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();

    final rows = await SupabaseBootstrap.client
        .from('mothers_club_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Set<String>> fetchMyLikedPostIds(String userId) async {
    if (!SupabaseBootstrap.isEnabled) return {};
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();

    final rows = await SupabaseBootstrap.client
        .from('mothers_club_likes')
        .select('post_id')
        .eq('user_id', userId);

    return {
      for (final row in List<Map<String, dynamic>>.from(rows as List))
        row['post_id'] as String,
    };
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool liked,
  }) async {
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    final client = SupabaseBootstrap.client;

    if (liked) {
      await client.from('mothers_club_likes').delete().match({
        'post_id': postId,
        'user_id': userId,
      });
    } else {
      await client.from('mothers_club_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String authorDisplayName,
    required String body,
  }) async {
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    await SupabaseBootstrap.client.from('mothers_club_comments').insert({
      'post_id': postId,
      'author_id': userId,
      'author_display_name': authorDisplayName,
      'body': body,
    });
  }

  Future<String> uploadPostImage({
    required String userId,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();

    final safeExt =
        extension.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final ext = safeExt.isEmpty ? 'jpg' : safeExt;
    final path = 'posts/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await SupabaseBootstrap.client.storage.from(_imageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    return path;
  }

  Future<void> createPost({
    required String userId,
    required String authorDisplayName,
    required String title,
    required String body,
    String? tag,
    String? categoryId,
    String? imageStoragePath,
  }) async {
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    await SupabaseBootstrap.client.from('mothers_club_posts').insert({
      'author_id': userId,
      'author_display_name': authorDisplayName,
      'title': title,
      'body': body,
      'tag': tag,
      'category_id': categoryId,
      'image_storage_path': imageStoragePath,
      'publish_status': 'review',
    });
  }
}
