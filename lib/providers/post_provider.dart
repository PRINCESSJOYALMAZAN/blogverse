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
      final fetched = (await _attachProfiles(rows)).map(Post.fromMap).toList();
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
    final rows = await _attachProfiles([row]);
    return Post.fromMap(rows.first);
  }

  Future<List<Post>> getPostsByUser(String userId) async {
    final rows = await SupabaseService.client
        .from('posts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (await _attachProfiles(rows)).map(Post.fromMap).toList();
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

  Future<void> loadComments(String postId) async {
    try {
      final rows = await SupabaseService.client
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      commentsByPost[postId] =
          (await _attachProfiles(rows)).map(ForumComment.fromMap).toList();
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
}
