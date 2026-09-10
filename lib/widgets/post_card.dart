import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import 'image_picker_grid.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final Post post;

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
        constraints: const BoxConstraints(maxWidth: 620),
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.go('/posts/${post.id}'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFFE5B589),
                        backgroundImage: post.authorAvatarUrl == null
                            ? null
                            : NetworkImage(post.authorAvatarUrl!),
                        child: post.authorAvatarUrl == null
                            ? const Icon(Icons.person_outline, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName?.isNotEmpty == true
                                  ? post.authorName!
                                  : 'Forum member',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '@member - ${DateFormat.MMMd().add_jm().format(post.createdAt)}',
                              style: const TextStyle(
                                color: Color(0xFF8A93A8),
                                fontSize: 11,
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
                              await context.read<PostProvider>().deletePost(post);
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'serif',
                          fontWeight: FontWeight.w900,
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
                      height: 1.55,
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
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Color(0xFF9AA4B7),
                      ),
                      const SizedBox(width: 5),
                      const Text('Open discussion'),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/posts/${post.id}'),
                        child: const Text('Read more'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
