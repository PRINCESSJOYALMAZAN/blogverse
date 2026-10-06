import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<Post> _postFuture;

  @override
  void initState() {
    super.initState();
    final provider = context.read<PostProvider>();
    _postFuture = provider.getPost(widget.postId);
    provider.loadComments(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final provider = context.watch<PostProvider>();
    final comments = provider.commentsByPost[widget.postId] ?? [];
    return AppShell(
      child: FutureBuilder<Post>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 32),
                        const SizedBox(height: 10),
                        Text(snapshot.error.toString()),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Back to feed'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final post = snapshot.data!;
          final isOwner = auth.user?.id == post.userId;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (isOwner) ...[
                            IconButton(
                              tooltip: 'Edit post',
                              onPressed: () => context.go('/edit/${post.id}'),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete post',
                              onPressed: () async {
                                final confirmed = await _confirmAction(
                                  context,
                                  title: 'Delete post?',
                                  message: 'This will also delete all comments on this post.',
                                );
                                if (!confirmed || !context.mounted) return;
                                await provider.deletePost(post);
                                if (context.mounted) context.go('/');
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ],
                      ),
                      InkWell(
                        onTap: () => context.go('/users/${post.userId}'),
                        child: Text(
                          '${post.authorName ?? 'Forum member'} - ${DateFormat.yMMMd().add_jm().format(post.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(post.body),
                      const SizedBox(height: 16),
                      ImageStrip(urls: post.imageUrls, height: 230),
                      const SizedBox(height: 12),
                      PostInteractionBar(post: post),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Comments',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (auth.isLoggedIn)
                CommentEditor(postId: widget.postId)
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Login to add a comment with images.'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => context.go('/login'),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              for (final comment in comments) CommentTile(comment: comment),
            ],
          );
        },
      ),
    );
  }
}

class CommentTile extends StatefulWidget {
  const CommentTile({super.key, required this.comment});

  final ForumComment comment;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final isOwner = auth.user?.id == widget.comment.userId;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _editing
            ? CommentEditor(
                postId: widget.comment.postId,
                comment: widget.comment,
                onDone: () => setState(() => _editing = false),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => context.go('/users/${widget.comment.userId}'),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: widget.comment.authorAvatarUrl == null
                              ? null
                              : NetworkImage(widget.comment.authorAvatarUrl!),
                          child: widget.comment.authorAvatarUrl == null
                              ? const Icon(Icons.person_outline, size: 18)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go('/users/${widget.comment.userId}'),
                          child: Text(
                            '${widget.comment.authorName ?? 'Member'} - ${DateFormat.MMMd().add_jm().format(widget.comment.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                      if (isOwner) ...[
                        IconButton(
                          tooltip: 'Edit comment',
                          onPressed: () => setState(() => _editing = true),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Delete comment',
                          onPressed: () async {
                            final confirmed = await _confirmAction(
                              context,
                              title: 'Delete comment?',
                              message: 'This comment and its images will be removed.',
                            );
                            if (confirmed && context.mounted) {
                              await context
                                  .read<PostProvider>()
                                  .deleteComment(widget.comment);
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.comment.body),
                  const SizedBox(height: 10),
                  ImageStrip(urls: widget.comment.imageUrls, height: 130),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: auth.isLoggedIn
                          ? () => context
                              .read<PostProvider>()
                              .toggleCommentReaction(widget.comment)
                          : null,
                      icon: Icon(
                        widget.comment.reactedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: widget.comment.reactedByMe ? Colors.pink : null,
                      ),
                      label: Text('${widget.comment.reactionCount} React'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

Future<bool> _confirmAction(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

class CommentEditor extends StatefulWidget {
  const CommentEditor({
    super.key,
    required this.postId,
    this.comment,
    this.onDone,
  });

  final String postId;
  final ForumComment? comment;
  final VoidCallback? onDone;

  @override
  State<CommentEditor> createState() => _CommentEditorState();
}

class _CommentEditorState extends State<CommentEditor> {
  final _body = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _existingImages = [];
  final List<XFile> _newImages = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final comment = widget.comment;
    if (comment != null) {
      _body.text = comment.body;
      _existingImages.addAll(comment.imageUrls);
    }
  }

  Future<void> _pickImages() async {
    List<XFile> images;
    try {
      images = await _picker.pickMultiImage(imageQuality: 100);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select images: $error')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _newImages.addAll(images));
  }

  Future<void> _save() async {
    if (_body.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await context.read<PostProvider>().saveComment(
            id: widget.comment?.id,
            postId: widget.postId,
            body: _body.text,
            keptImages: _existingImages,
            newImages: _newImages,
          );
      _body.clear();
      _newImages.clear();
      widget.onDone?.call();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _body,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Write a comment',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            ImagePickerGrid(
              existingUrls: _existingImages,
              newImages: _newImages,
              onRemoveExisting: (url) =>
                  setState(() => _existingImages.remove(url)),
              onRemoveNew: (image) => setState(() => _newImages.remove(image)),
              onAddImages: _pickImages,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.send_outlined),
              label: Text(widget.comment == null ? 'Comment' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
