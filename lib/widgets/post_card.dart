import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import 'image_picker_grid.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.maxWidth = 620,
  });

  final Post post;
  final double maxWidth;

  List<String> get _tags {
    final text = '${post.title} ${post.body}'.toLowerCase();
    final tags = <String>[];
    if (text.contains('flutter')) tags.add('Flutter');
    if (text.contains('supabase')) tags.add('Supabase');
    if (text.contains('design')) tags.add('Design');
    if (text.contains('mobile') || text.contains('app')) tags.add('Mobile');
    if (text.contains('storage') || post.imageUrls.isNotEmpty) {
      tags.add('Storage');
    }
    return tags.isEmpty ? const ['Community'] : tags.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final isOwner = auth.user?.id == post.userId;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/posts/${post.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => context.go('/users/${post.userId}'),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF5B4DF7),
                          backgroundImage: post.authorAvatarUrl == null
                              ? null
                              : NetworkImage(post.authorAvatarUrl!),
                          child: post.authorAvatarUrl == null
                              ? Text(
                                  (post.authorName?.isNotEmpty == true
                                          ? post.authorName!
                                          : 'M')
                                      .characters
                                      .first
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => context.go('/users/${post.userId}'),
                              child: Text(
                                post.authorName?.isNotEmpty == true
                                    ? post.authorName!
                                    : 'Forum member',
                                style: const TextStyle(
                                  color: Color(0xFF1E2A44),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat.MMMd().add_jm().format(post.createdAt),
                              style: const TextStyle(
                                color: Color(0xFF8A93A8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isOwner)
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') context.go('/edit/${post.id}');
                            if (value == 'delete') {
                              await context
                                  .read<PostProvider>()
                                  .deletePost(post);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in _tags) _TagPill(label: tag),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF43516A),
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                  if (post.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ImageStrip(urls: post.imageUrls, height: 168),
                    ),
                  ],
                  const SizedBox(height: 14),
                  PostInteractionBar(post: post),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PostInteractionBar extends StatelessWidget {
  const PostInteractionBar({super.key, required this.post});

  final Post post;

  static const reactions = <String, (String, IconData, Color)>{
    'like': ('Like', Icons.thumb_up_alt_rounded, Color(0xFF2563EB)),
    'love': ('Love', Icons.favorite_rounded, Color(0xFFE11D48)),
    'sad': ('Sad', Icons.sentiment_dissatisfied_rounded, Color(0xFFEAB308)),
    'angry': ('Angry', Icons.mood_bad_rounded, Color(0xFFEA580C)),
  };

  Future<void> _share(BuildContext context) async {
    final url = '${Uri.base.origin}/#/posts/${post.id}';
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post link copied.')),
      );
    }
  }

  Future<void> _chooseReaction(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final entry in reactions.entries)
                _ReactionChoice(
                  label: entry.value.$1,
                  icon: entry.value.$2,
                  color: entry.value.$3,
                  selected: post.myReaction == entry.key,
                  onTap: () => Navigator.pop(context, entry.key),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await context.read<PostProvider>().togglePostReaction(post, selected);
  }

  Future<void> _react(BuildContext context) async {
    if (!context.read<AuthStateProvider>().isLoggedIn) {
      context.go('/login');
      return;
    }
    await context.read<PostProvider>().togglePostReaction(
          post,
          post.myReaction ?? 'like',
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final reaction = post.myReaction == null ? null : reactions[post.myReaction!];
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onLongPress: auth.isLoggedIn ? () => _chooseReaction(context) : null,
            child: TextButton.icon(
              onPressed: () => _react(context),
              icon: Icon(
                reaction?.$2 ?? Icons.thumb_up_alt_outlined,
                size: 17,
                color: reaction?.$3,
              ),
              label: Text(
                post.totalReactions == 0
                    ? 'React'
                    : '${reaction?.$1 ?? 'React'} ${post.totalReactions}',
              ),
            ),
          ),
        ),
        Expanded(
          child: TextButton.icon(
            onPressed: () => context.go('/posts/${post.id}'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
            label: const Text('Comment'),
          ),
        ),
        Expanded(
          child: TextButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.share_outlined, size: 17),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }
}

class _ReactionChoice extends StatelessWidget {
  const _ReactionChoice({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: selected ? color : color.withValues(alpha: .12),
              child: Icon(icon, color: selected ? Colors.white : color),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = switch (label) {
      'Supabase' || 'Storage' => (
          const Color(0xFFE9FFF4),
          const Color(0xFF008568),
        ),
      'Design' || 'UI/UX' => (
          const Color(0xFFFFEBF6),
          const Color(0xFFD41474),
        ),
      'Mobile' => (
          const Color(0xFFF4EAFF),
          const Color(0xFF7A24FF),
        ),
      _ => (
          const Color(0xFFEEF4FF),
          const Color(0xFF415FFF),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
