import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../services/supabase_service.dart';

class PostProvider extends ChangeNotifier {
  final int pageSize = 6;
  final List<Post> posts = [];
  final Map<String, List<ForumComment>> commentsByPost = {};
  bool loading = false;
  bool hasMore = true;
  String? error;
  int _page = 0;

  Future<void> loadInitial() async {
    posts.clear();
    error = null;
    _page = 0;
    hasMore = true;
    await loadMore();
  }

  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final from = _page * pageSize;
      final to = from + pageSize - 1;
      final rows = await SupabaseService.client
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .range(from, to);
      final fetched = (await _attachPostReactions(await _attachProfiles(rows)))
          .map(Post.fromMap)
          .toList();
      posts.addAll(fetched);
      hasMore = fetched.length == pageSize;
      _page++;
    } catch (exception) {
      error = _friendlyError(exception);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Post> getPost(String id) async {
    final row = await SupabaseService.client
        .from('posts')
        .select()
        .eq('id', id)
        .single();
    final rows = await _attachPostReactions(await _attachProfiles([row]));
    return Post.fromMap(rows.first);
  }

  Future<List<Post>> getPostsByUser(String userId) async {
    final rows = await SupabaseService.client
        .from('posts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (await _attachPostReactions(await _attachProfiles(rows)))
        .map(Post.fromMap)
        .toList();
  }

  Future<void> savePost({
    String? id,
    required String title,
    required String body,
    required List<String> keptImages,
    required List<XFile> newImages,
  }) async {
    await SupabaseService.ensureCurrentProfile();
    final uploaded =
        await SupabaseService.uploadImages(newImages, folder: 'posts');
    final imageUrls = [...keptImages, ...uploaded];
    try {
      if (id == null) {
        await SupabaseService.client.from('posts').insert({
          'user_id': SupabaseService.userId,
          'title': title.trim(),
          'body': body.trim(),
          'image_urls': imageUrls,
        });
      } else {
        final existing = await getPost(id);
        final deleted = existing.imageUrls
            .where((url) => !keptImages.contains(url))
            .toList();
        await SupabaseService.client.from('posts').update({
          'title': title.trim(),
          'body': body.trim(),
          'image_urls': imageUrls,
        }).eq('id', id);
        await SupabaseService.deleteByPublicUrls(deleted);
      }
    } catch (_) {
      await SupabaseService.deleteByPublicUrls(uploaded);
      rethrow;
    }
    await loadInitial();
  }

  Future<void> deletePost(Post post) async {
    await SupabaseService.client.from('posts').delete().eq('id', post.id);
    await SupabaseService.deleteByPublicUrls(post.imageUrls);
    await loadInitial();
  }

  Future<void> togglePostReaction(Post post, String reaction) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    final existing = await SupabaseService.client
        .from('post_reactions')
        .select('reaction')
        .eq('post_id', post.id)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing?['reaction'] == reaction) {
      await SupabaseService.client
          .from('post_reactions')
          .delete()
          .eq('post_id', post.id)
          .eq('user_id', userId);
    } else if (existing == null) {
      await SupabaseService.client.from('post_reactions').insert({
        'post_id': post.id,
        'user_id': userId,
        'reaction': reaction,
      });
    } else {
      await SupabaseService.client
          .from('post_reactions')
          .update({'reaction': reaction})
          .eq('post_id', post.id)
          .eq('user_id', userId);
    }
    final updated = await getPost(post.id);
    final index = posts.indexWhere((item) => item.id == post.id);
    if (index != -1) posts[index] = updated;
    notifyListeners();
  }

  Future<void> loadComments(String postId) async {
    try {
      final rows = await SupabaseService.client
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      final comments = await _attachProfiles(rows);
      final ids = comments.map((row) => row['id'] as String).toList();
      if (ids.isNotEmpty) {
        final reactions = await SupabaseService.client
            .from('comment_reactions')
            .select('comment_id, user_id')
            .inFilter('comment_id', ids);
        final counts = <String, int>{};
        final mine = <String>{};
        for (final reaction in reactions) {
          final commentId = reaction['comment_id'] as String;
          counts[commentId] = (counts[commentId] ?? 0) + 1;
          if (reaction['user_id'] == SupabaseService.client.auth.currentUser?.id) {
            mine.add(commentId);
          }
        }
        for (final row in comments) {
          row['reaction_count'] = counts[row['id']] ?? 0;
          row['reacted_by_me'] = mine.contains(row['id']);
        }
      }
      commentsByPost[postId] = comments.map(ForumComment.fromMap).toList();
      error = null;
    } catch (exception) {
      error = _friendlyError(exception);
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveComment({
    String? id,
    required String postId,
    required String body,
    required List<String> keptImages,
    required List<XFile> newImages,
  }) async {
    await SupabaseService.ensureCurrentProfile();
    final uploaded =
        await SupabaseService.uploadImages(newImages, folder: 'comments');
    final imageUrls = [...keptImages, ...uploaded];
    try {
      if (id == null) {
        await SupabaseService.client.from('comments').insert({
          'post_id': postId,
          'user_id': SupabaseService.userId,
          'body': body.trim(),
          'image_urls': imageUrls,
        });
      } else {
        final current = commentsByPost[postId]!.firstWhere((c) => c.id == id);
        final deleted = current.imageUrls
            .where((url) => !keptImages.contains(url))
            .toList();
        await SupabaseService.client.from('comments').update({
          'body': body.trim(),
          'image_urls': imageUrls,
        }).eq('id', id);
        await SupabaseService.deleteByPublicUrls(deleted);
      }
    } catch (_) {
      await SupabaseService.deleteByPublicUrls(uploaded);
      rethrow;
    }
    await loadComments(postId);
  }

  Future<void> deleteComment(ForumComment comment) async {
    await SupabaseService.client.from('comments').delete().eq('id', comment.id);
    await SupabaseService.deleteByPublicUrls(comment.imageUrls);
    await loadComments(comment.postId);
  }

  Future<void> toggleCommentReaction(ForumComment comment) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    final existing = await SupabaseService.client
        .from('comment_reactions')
        .select('comment_id')
        .eq('comment_id', comment.id)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing == null) {
      await SupabaseService.client.from('comment_reactions').insert({
        'comment_id': comment.id,
        'user_id': userId,
      });
    } else {
      await SupabaseService.client
          .from('comment_reactions')
          .delete()
          .eq('comment_id', comment.id)
          .eq('user_id', userId);
    }
    await loadComments(comment.postId);
  }

  String _friendlyError(Object exception) {
    final message = exception.toString();
    if (message.contains('schema cache') ||
        message.contains('does not exist')) {
      return 'Database tables are not set up yet. Run app/supabase.sql in your Supabase SQL editor.';
    }
    if (message.contains('row-level security') || message.contains('policy')) {
      return 'Supabase permissions need to be updated. Run the latest app/supabase.sql in your Supabase SQL editor.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  Future<List<Map<String, dynamic>>> _attachProfiles(List<dynamic> rows) async {
    final mapped = rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final userIds = mapped
        .map((row) => row['user_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    if (userIds.isEmpty) return mapped;

    final profileRows = await SupabaseService.client
        .from('profiles')
        .select('id, name, avatar_url')
        .inFilter('id', userIds);
    final profiles = {
      for (final profile in profileRows)
        profile['id'] as String: Map<String, dynamic>.from(profile as Map),
    };

    return [
      for (final row in mapped)
        {
          ...row,
          'profiles': profiles[row['user_id']],
        },
    ];
  }

  Future<List<Map<String, dynamic>>> _attachPostReactions(
    List<Map<String, dynamic>> rows,
  ) async {
    final ids = rows.map((row) => row['id'] as String).toList();
    if (ids.isEmpty) return rows;
    final reactions = await SupabaseService.client
        .from('post_reactions')
        .select('post_id, user_id, reaction')
        .inFilter('post_id', ids);
    final counts = <String, Map<String, int>>{};
    final mine = <String, String>{};
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    for (final reaction in reactions) {
      final postId = reaction['post_id'] as String;
      final kind = reaction['reaction'] as String;
      final postCounts = counts.putIfAbsent(postId, () => {});
      postCounts[kind] = (postCounts[kind] ?? 0) + 1;
      if (reaction['user_id'] == currentUserId) mine[postId] = kind;
    }
    return [
      for (final row in rows)
        {
          ...row,
          'reaction_counts': counts[row['id']] ?? const <String, int>{},
          'my_reaction': mine[row['id']],
        },
    ];
  }
}
