import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_profile.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_shell.dart';

const _kIndigo = Color(0xFF4F46E5);
const _kCyan = Color(0xFF0891B2);
const _kEmerald = Color(0xFF059669);
const _kInk = Color(0xFF0F172A);
const _kSlate700 = Color(0xFF334155);
const _kSlate500 = Color(0xFF64748B);
const _kSlate400 = Color(0xFF94A3B8);
const _kSlate200 = Color(0xFFE2E8F0);
const _kSlate100 = Color(0xFFF1F5F9);
const _kRed = Color(0xFFDC2626);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _picker = ImagePicker();
  AppProfile? _profile;
  Future<List<Post>>? _userPostsFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    final profileProvider = context.read<ProfileProvider>();
    final postProvider = context.read<PostProvider>();
    final userId = context.read<AuthStateProvider>().user?.id;

    await profileProvider.load();
    if (!mounted) return;

    final loadedProfile = profileProvider.profile;
    _name.text = loadedProfile?.name ?? '';
    setState(() {
      _profile = loadedProfile;
      if (userId != null) {
        _userPostsFuture = postProvider.getPostsByUser(userId);
      }
    });
  }

  Future<void> _refreshFromProvider({
    required ProfileProvider profileProvider,
    required PostProvider postProvider,
    required String? userId,
  }) async {
    if (!mounted) return;
    setState(() {
      _profile = profileProvider.profile;
      if (userId != null) {
        _userPostsFuture = postProvider.getPostsByUser(userId);
      }
    });
  }

  Future<void> _saveName() async {
    setState(() => _saving = true);
    final profileProvider = context.read<ProfileProvider>();
    final postProvider = context.read<PostProvider>();
    final userId = context.read<AuthStateProvider>().user?.id;

    try {
      await profileProvider.updateName(_name.text);
      await _refreshFromProvider(
        profileProvider: profileProvider,
        postProvider: postProvider,
        userId: userId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully'),
            backgroundColor: _kEmerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (image == null || !mounted) return;

    final profileProvider = context.read<ProfileProvider>();
    final postProvider = context.read<PostProvider>();
    final userId = context.read<AuthStateProvider>().user?.id;

    try {
      await profileProvider.updateAvatar(image);
      await _refreshFromProvider(
        profileProvider: profileProvider,
        postProvider: postProvider,
        userId: userId,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteAvatar() async {
    final profileProvider = context.read<ProfileProvider>();
    final postProvider = context.read<PostProvider>();
    final userId = context.read<AuthStateProvider>().user?.id;

    try {
      await profileProvider.deleteAvatar();
      await _refreshFromProvider(
        profileProvider: profileProvider,
        postProvider: postProvider,
        userId: userId,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _pickCover() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
      maxWidth: 1800,
    );
    if (image == null || !mounted) return;

    final profileProvider = context.read<ProfileProvider>();
    final postProvider = context.read<PostProvider>();
    final userId = context.read<AuthStateProvider>().user?.id;

    try {
      await profileProvider.updateCover(image);
      await _refreshFromProvider(
        profileProvider: profileProvider,
        postProvider: postProvider,
        userId: userId,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteCover() async {
    final profileProvider = context.read<ProfileProvider>();
    final postProvider = context.read<PostProvider>();
    final userId = context.read<AuthStateProvider>().user?.id;

    try {
      await profileProvider.deleteCover();
      await _refreshFromProvider(
        profileProvider: profileProvider,
        postProvider: postProvider,
        userId: userId,
      );
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final profile = _profile;
    final email = profile?.email ?? auth.user?.email ?? '';
    final displayName = profile?.name?.trim().isNotEmpty == true
        ? profile!.name!.trim()
        : email.contains('@')
            ? email.split('@').first
            : 'Member';
    final handle =
        '@${displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '')}';

    return AppShell(
      selectedIndex: 2,
      profile: profile,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _ProfileHero(
                displayName: displayName,
                email: email,
                coverUrl: profile?.coverUrl,
                fallbackImageUrl: profile?.avatarUrl,
                onChangeCover: _pickCover,
                onDeleteCover: _deleteCover,
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 28,
                      24,
                      compact ? 16 : 28,
                      48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileSummaryCard(
                          compact: compact,
                          profile: profile,
                          displayName: displayName,
                          handle: handle,
                          email: email,
                          userPostsFuture: _userPostsFuture,
                          nameController: _name,
                          saving: _saving,
                          onChangePhoto: _pickAvatar,
                          onDeletePhoto: _deleteAvatar,
                          onSave: _saveName,
                        ),
                        const SizedBox(height: 18),
                        _UserPostsSection(postsFuture: _userPostsFuture),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.coverUrl,
    required this.fallbackImageUrl,
    required this.onChangeCover,
    required this.onDeleteCover,
  });

  final String displayName;
  final String email;
  final String? coverUrl;
  final String? fallbackImageUrl;
  final VoidCallback onChangeCover;
  final VoidCallback onDeleteCover;

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;
    final backgroundUrl = hasCover ? coverUrl : fallbackImageUrl;
    final hasBackground = backgroundUrl?.isNotEmpty == true;
    final titleBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: .18),
            ),
          ),
          child: const Text(
            'Profile cover',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .86),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        FilledButton.icon(
          onPressed: onChangeCover,
          icon: const Icon(Icons.wallpaper_outlined, size: 18),
          label: Text(hasCover ? 'Change cover' : 'Add cover'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _kInk,
          ),
        ),
        if (hasCover)
          IconButton.filledTonal(
            tooltip: 'Remove cover',
            onPressed: onDeleteCover,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _kRed,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
      ],
    );

    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: _kIndigo,
        image: hasBackground
            ? DecorationImage(
                image: NetworkImage(backgroundUrl!),
                fit: BoxFit.cover,
              )
            : null,
        gradient: hasBackground
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), _kIndigo, Color(0xFF7C3AED)],
              ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: hasBackground
                ? [
                    Colors.black.withValues(alpha: hasCover ? .12 : .34),
                    Colors.black.withValues(alpha: hasCover ? .58 : .66),
                  ]
                : [
                    Colors.black.withValues(alpha: .02),
                    Colors.black.withValues(alpha: .10),
                  ],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 620) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleBlock,
                      const SizedBox(height: 14),
                      actions,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 16),
                    actions,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.compact,
    required this.profile,
    required this.displayName,
    required this.handle,
    required this.email,
    required this.userPostsFuture,
    required this.nameController,
    required this.saving,
    required this.onChangePhoto,
    required this.onDeletePhoto,
    required this.onSave,
  });

  final bool compact;
  final AppProfile? profile;
  final String displayName;
  final String handle;
  final String email;
  final Future<List<Post>>? userPostsFuture;
  final TextEditingController nameController;
  final bool saving;
  final VoidCallback onChangePhoto;
  final VoidCallback onDeletePhoto;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kSlate200),
        boxShadow: [
          BoxShadow(
            color: _kInk.withValues(alpha: .06),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 24),
        child: compact ? _compactLayout(context) : _wideLayout(context),
      ),
    );
  }

  Widget _wideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileAvatar(
          avatarUrl: profile?.avatarUrl,
          displayName: displayName,
          onChangePhoto: onChangePhoto,
        ),
        const SizedBox(width: 24),
        Expanded(child: _profileDetails()),
        const SizedBox(width: 24),
        SizedBox(width: 280, child: _accountForm()),
      ],
    );
  }

  Widget _compactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _ProfileAvatar(
              avatarUrl: profile?.avatarUrl,
              displayName: displayName,
              onChangePhoto: onChangePhoto,
              size: 86,
            ),
            const SizedBox(width: 16),
            Expanded(child: _identityText()),
          ],
        ),
        const SizedBox(height: 18),
        _stats(),
        const SizedBox(height: 22),
        _accountForm(),
      ],
    );
  }

  Widget _profileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _identityText(),
        const SizedBox(height: 18),
        _stats(),
      ],
    );
  }

  Widget _identityText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _kInk,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          handle,
          style: const TextStyle(
            color: _kSlate500,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _InfoPill(
              icon: Icons.verified_user_outlined,
              label: 'Member',
            ),
            _InfoPill(
              icon: profile?.avatarUrl == null
                  ? Icons.person_outline_rounded
                  : Icons.photo_camera_outlined,
              label: profile?.avatarUrl == null ? 'Default photo' : 'Photo set',
            ),
            _InfoPill(
              icon: profile?.coverUrl == null
                  ? Icons.wallpaper_outlined
                  : Icons.landscape_outlined,
              label: profile?.coverUrl == null ? 'No cover yet' : 'Cover set',
            ),
          ],
        ),
      ],
    );
  }

  Widget _stats() {
    return FutureBuilder<List<Post>>(
      future: userPostsFuture,
      builder: (context, snapshot) {
        final postCount = snapshot.hasData ? '${snapshot.data!.length}' : '...';
        return Row(
          children: [
            Expanded(
              child: _StatBox(
                value: postCount,
                label: 'Posts',
                icon: Icons.article_outlined,
                color: _kIndigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                value: profile?.coverUrl == null ? 'No' : 'Yes',
                label: 'Cover photo',
                icon: Icons.landscape_outlined,
                color: _kCyan,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _accountForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Account',
          style: TextStyle(
            color: _kInk,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        _TwField(
          label: 'Email address',
          initialValue: email,
          readOnly: true,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 12),
        _TwField(
          label: 'Display name',
          controller: nameController,
          hint: 'Enter your name',
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(saving ? 'Saving' : 'Save'),
              ),
            ),
            if (profile?.avatarUrl != null) ...[
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Remove photo',
                onPressed: onDeletePhoto,
                color: _kRed,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.displayName,
    required this.onChangePhoto,
    this.size = 116,
  });

  final String? avatarUrl;
  final String displayName;
  final VoidCallback onChangePhoto;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_kIndigo, _kCyan]),
              boxShadow: [
                BoxShadow(
                  color: _kIndigo.withValues(alpha: .18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: _kSlate100,
              backgroundImage: hasPhoto ? NetworkImage(avatarUrl!) : null,
              child: hasPhoto
                  ? null
                  : Text(
                      displayName.characters.first.toUpperCase(),
                      style: TextStyle(
                        color: _kIndigo,
                        fontSize: size * .34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: IconButton.filled(
              tooltip: 'Change photo',
              onPressed: onChangePhoto,
              style: IconButton.styleFrom(
                backgroundColor: _kInk,
                foregroundColor: Colors.white,
                minimumSize: const Size(38, 38),
                fixedSize: const Size(38, 38),
              ),
              icon: const Icon(Icons.photo_camera_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kSlate100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kSlate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _kSlate500),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _kSlate700,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: color),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: _kInk,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _kSlate500,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TwField extends StatelessWidget {
  const _TwField({
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.readOnly = false,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final bool readOnly;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kSlate700,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly ? _kSlate500 : _kInk,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: _kSlate400)
                : null,
            filled: true,
            fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kSlate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kIndigo, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserPostsSection extends StatelessWidget {
  const _UserPostsSection({required this.postsFuture});

  final Future<List<Post>>? postsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: postsFuture,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? const <Post>[];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kSlate200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your Posts',
                        style: TextStyle(
                          color: _kInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (snapshot.hasError)
                  _EmptyState(
                    icon: Icons.error_outline,
                    message: snapshot.error.toString(),
                  )
                else if (snapshot.connectionState != ConnectionState.waiting &&
                    posts.isEmpty)
                  const _EmptyState(
                    icon: Icons.article_outlined,
                    message: 'You have not published any posts yet.',
                  )
                else
                  ...posts.map((post) => _ProfilePostTile(post: post)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfilePostTile extends StatelessWidget {
  const _ProfilePostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/posts/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 64,
                  height: 64,
                  color: _kSlate100,
                  child: post.imageUrls.isEmpty
                      ? const Icon(Icons.image_outlined, color: _kSlate400)
                      : Image.network(
                          post.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.image_not_supported_outlined,
                            color: _kSlate400,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _kSlate500, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat.MMMd().add_jm().format(post.createdAt),
                      style: const TextStyle(
                        color: _kSlate400,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: _kSlate400),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kSlate200),
      ),
      child: Column(
        children: [
          Icon(icon, color: _kSlate400),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kSlate500),
          ),
        ],
      ),
    );
  }
}
