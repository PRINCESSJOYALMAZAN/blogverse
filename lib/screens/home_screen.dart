import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/post_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostProvider>();
    return AppShell(
      child: RefreshIndicator(
        onRefresh: posts.loadInitial,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontFamily: 'serif',
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    Text(
                      '${posts.posts.length} posts',
                      style: const TextStyle(
                        color: Color(0xFF8A93A8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        _FeedTab(
                            label: 'Latest',
                            icon: Icons.schedule,
                            active: true),
                        SizedBox(width: 24),
                        _FeedTab(label: 'Trending', icon: Icons.trending_up),
                      ],
                    ),
                    const Divider(height: 1),
                    if (posts.error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorPanel(
                        message: posts.error!,
                        onRetry: posts.loadInitial,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (posts.posts.isEmpty && posts.loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
            if (posts.posts.isEmpty && !posts.loading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                      child: Text('No posts yet. Start the conversation.')),
                ),
              ),
            for (final post in posts.posts) PostCard(post: post),
            if (posts.hasMore)
              Center(
                child: OutlinedButton.icon(
                  onPressed: posts.loading ? null : posts.loadMore,
                  icon: posts.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.keyboard_arrow_down),
                  label: const Text('Load more'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.label,
    required this.icon,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? const Color(0xFF6258FF) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: active ? const Color(0xFF6258FF) : const Color(0xFF586275),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF6258FF) : const Color(0xFF586275),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7F7),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB42318)),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
