import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/post_card.dart';

const _kInk = Color(0xFF13213A);
const _kMuted = Color(0xFF71809B);
const _kLine = Color(0xFFE2E8F0);
const _kViolet = Color(0xFF5B4DF7);
const _kOrange = Color(0xFFF59E0B);

enum _FeedFilter { all, mine, withImages, latest }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  _FeedFilter _filter = _FeedFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostProvider>();
    final auth = context.watch<AuthStateProvider>();
    final posts = _visiblePosts(postsProvider.posts, auth.user?.id);
    final compact = MediaQuery.sizeOf(context).width < 1040;

    return AppShell(
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: RefreshIndicator(
          onRefresh: postsProvider.loadInitial,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 28,
                  18,
                  compact ? 16 : 28,
                  48,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: compact
                          ? Column(
                              children: [
                                _mainFeed(postsProvider, posts, auth),
                                const SizedBox(height: 18),
                                _HomeRail(
                                  posts: postsProvider.posts,
                                  onTagTap: _searchForTag,
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _mainFeed(postsProvider, posts, auth),
                                ),
                                const SizedBox(width: 22),
                                SizedBox(
                                  width: 310,
                                  child: _HomeRail(
                                    posts: postsProvider.posts,
                                    onTagTap: _searchForTag,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainFeed(
    PostProvider postsProvider,
    List<Post> posts,
    AuthStateProvider auth,
  ) {
    final displayName = _displayName(auth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WelcomePanel(displayName: displayName),
        const SizedBox(height: 14),
        _QuickComposer(
          displayName: displayName,
          onWrite: () =>
              auth.isLoggedIn ? context.go('/new') : context.go('/login'),
        ),
        const SizedBox(height: 14),
        _FilterBar(
          selected: _filter,
          onSelected: (filter) => setState(() => _filter = filter),
        ),
        if (postsProvider.error != null) ...[
          const SizedBox(height: 14),
          _ErrorPanel(
            message: postsProvider.error!,
            onRetry: postsProvider.loadInitial,
          ),
        ],
        const SizedBox(height: 14),
        if (posts.isEmpty && postsProvider.loading)
          const _LoadingPanel()
        else if (posts.isEmpty)
          _EmptyFeed(
            onWrite: () => context.go(auth.isLoggedIn ? '/new' : '/login'),
          )
        else
          ...posts.map(
            (post) => PostCard(post: post, maxWidth: double.infinity),
          ),
        if (postsProvider.hasMore) ...[
          const SizedBox(height: 6),
          Center(
            child: OutlinedButton.icon(
              onPressed: postsProvider.loading ? null : postsProvider.loadMore,
              icon: postsProvider.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.keyboard_arrow_down_rounded),
              label: const Text('Load more'),
            ),
          ),
        ],
      ],
    );
  }

  List<Post> _visiblePosts(List<Post> source, String? userId) {
    final query = _search.text.trim().toLowerCase();
    var posts = source.where((post) {
      if (query.isEmpty) return true;
      final haystack = [
        post.title,
        post.body,
        post.authorName ?? '',
        ..._tagsFor(post),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    posts = switch (_filter) {
      _FeedFilter.all => posts,
      _FeedFilter.mine => userId == null
          ? <Post>[]
          : posts.where((post) => post.userId == userId).toList(),
      _FeedFilter.withImages =>
        posts.where((post) => post.imageUrls.isNotEmpty).toList(),
      _FeedFilter.latest => posts
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    };
    return posts;
  }

  void _searchForTag(String tag) {
    setState(() {
      _search.text = tag;
      _filter = _FeedFilter.all;
    });
  }

  String _displayName(AuthStateProvider auth) {
    final user = auth.user;
    final metaName = user?.userMetadata?['name']?.toString().trim();
    if (metaName != null && metaName.isNotEmpty) return metaName;
    final email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Kobiko';
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E9FF)),
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF5FF), Color(0xFFF6F2FF)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good day, $displayName!',
                  style: const TextStyle(
                    color: _kInk,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Share your ideas, projects, and updates with the community.',
                  style: TextStyle(
                    color: Color(0xFF40516F),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kViolet,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _kViolet.withValues(alpha: .25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Text(
              'Keep creating',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickComposer extends StatelessWidget {
  const _QuickComposer({
    required this.displayName,
    required this.onWrite,
  });

  final String displayName;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _kViolet,
              child: Text(
                displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onWrite,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFCFF),
                    border: Border.all(color: _kLine),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'What is on your mind? Share an update, question, or idea...',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF8290AA),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onWrite,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Post'),
              style: FilledButton.styleFrom(
                backgroundColor: _kViolet,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onSelected,
  });

  final _FeedFilter selected;
  final ValueChanged<_FeedFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChipButton(
          label: 'All',
          selected: selected == _FeedFilter.all,
          onTap: () => onSelected(_FeedFilter.all),
        ),
        _FilterChipButton(
          label: 'My posts',
          selected: selected == _FeedFilter.mine,
          onTap: () => onSelected(_FeedFilter.mine),
        ),
        _FilterChipButton(
          label: 'Images',
          selected: selected == _FeedFilter.withImages,
          onTap: () => onSelected(_FeedFilter.withImages),
        ),
        _FilterChipButton(
          label: 'Latest',
          selected: selected == _FeedFilter.latest,
          onTap: () => onSelected(_FeedFilter.latest),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      backgroundColor: selected ? _kViolet : Colors.white,
      side: BorderSide(color: selected ? _kViolet : _kLine),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF536179),
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _HomeRail extends StatelessWidget {
  const _HomeRail({
    required this.posts,
    required this.onTagTap,
  });

  final List<Post> posts;
  final ValueChanged<String> onTagTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TrendingTagsCard(posts: posts, onTagTap: onTagTap),
        const SizedBox(height: 14),
        _SuggestedPeopleCard(posts: posts),
        const SizedBox(height: 14),
        _RecentActivityCard(posts: posts),
      ],
    );
  }
}

class _TrendingTagsCard extends StatelessWidget {
  const _TrendingTagsCard({
    required this.posts,
    required this.onTagTap,
  });

  final List<Post> posts;
  final ValueChanged<String> onTagTap;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final post in posts) {
      for (final tag in _tagsFor(post)) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final tags = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = tags.isEmpty
        ? [
            const MapEntry('Flutter', 0),
            const MapEntry('Supabase', 0),
            const MapEntry('Design', 0),
          ]
        : tags.take(6).toList();

    return _RailCard(
      icon: Icons.local_fire_department_rounded,
      iconColor: const Color(0xFFEF4444),
      title: 'Trending tags',
      subtitle: 'Popular topics in the community',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in visible)
            InkWell(
              onTap: () => onTagTap(entry.key),
              borderRadius: BorderRadius.circular(999),
              child: _TagPill(
                label: entry.key,
                count: entry.value == 0 ? null : entry.value,
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestedPeopleCard extends StatelessWidget {
  const _SuggestedPeopleCard({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    final authors = <String, String?>{};
    for (final post in posts) {
      final name = post.authorName?.trim();
      if (name != null && name.isNotEmpty) {
        authors.putIfAbsent(name, () => post.authorAvatarUrl);
      }
    }
    final entries = authors.entries.take(4).toList();

    return _RailCard(
      icon: Icons.groups_2_outlined,
      iconColor: _kViolet,
      title: 'Community people',
      subtitle: 'Authors from Supabase profiles',
      child: entries.isEmpty
          ? const Text(
              'Authors will appear here after posts are published.',
              style: TextStyle(color: _kMuted, fontSize: 12, height: 1.4),
            )
          : Column(
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: _kViolet,
                          backgroundImage: entry.value == null
                              ? null
                              : NetworkImage(entry.value!),
                          child: entry.value == null
                              ? Text(
                                  entry.key.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.key,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.verified_outlined,
                          color: _kViolet,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    final recent = posts.take(3).toList();

    return _RailCard(
      icon: Icons.flash_on_rounded,
      iconColor: _kOrange,
      title: 'Recent activity',
      subtitle: 'Latest posts from the database',
      child: recent.isEmpty
          ? const Text(
              'No activity yet.',
              style: TextStyle(color: _kMuted, fontSize: 12),
            )
          : Column(
              children: [
                for (final post in recent)
                  InkWell(
                    onTap: () => context.go('/posts/${post.id}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _kMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _kInk,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _kInk,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _kMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = _tagColors(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.$2,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                color: colors.$2.withValues(alpha: .72),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
      margin: EdgeInsets.zero,
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

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.forum_outlined, color: _kMuted, size: 36),
            const SizedBox(height: 10),
            const Text(
              'No posts found',
              style: TextStyle(
                color: _kInk,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start the conversation or adjust your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onWrite,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Write a post'),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _tagsFor(Post post) {
  final text = '${post.title} ${post.body}'.toLowerCase();
  final tags = <String>[];
  if (text.contains('flutter')) tags.add('Flutter');
  if (text.contains('supabase')) tags.add('Supabase');
  if (text.contains('react')) tags.add('React');
  if (text.contains('next')) tags.add('Next.js');
  if (text.contains('python')) tags.add('Python');
  if (text.contains('design') || text.contains('ui')) tags.add('Design');
  if (text.contains('mobile') || text.contains('app')) tags.add('Mobile');
  if (post.imageUrls.isNotEmpty) tags.add('Images');
  return tags.isEmpty ? const ['Community'] : tags.take(4).toList();
}

(Color, Color) _tagColors(String label) {
  return switch (label) {
    'Supabase' => (const Color(0xFFE7F9EF), const Color(0xFF039855)),
    'Design' => (const Color(0xFFFFF2D9), const Color(0xFFD97706)),
    'Python' => (const Color(0xFFEAF4FF), const Color(0xFF2563EB)),
    'Mobile' => (const Color(0xFFFFE7F1), const Color(0xFFDB2777)),
    'React' || 'Next.js' => (const Color(0xFFEAF4FF), const Color(0xFF2563EB)),
    _ => (const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
  };
}
