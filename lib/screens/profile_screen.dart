import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

// This screen intentionally uses a few inline responsive widgets for the
// compact profile dashboard layout.
// ignore_for_file: prefer_const_constructors, unused_element, unused_element_parameter

// Shared BlogVerse brand purple used by Home, Write, Profile, and navigation.
const _kIndigo = Color(0xFF5B4DF7);
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
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _course = TextEditingController();
  final _location = TextEditingController();
  final _joinedYear = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  AppProfile? _profile;
  Future<List<Post>>? _userPostsFuture;
  Future<Map<String, int>>? _statsFuture;
  bool _saving = false;
  bool _avatarBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    final profileProvider = context.read<ProfileProvider>();
    final postProvider = context.read<PostProvider>();
    final authUserId = context.read<AuthStateProvider>().user?.id;
    final viewedUserId = widget.userId ?? authUserId;

    AppProfile? loadedProfile;
    if (widget.userId == null) {
      await profileProvider.load();
      loadedProfile = profileProvider.profile;
    } else {
      loadedProfile = await profileProvider.getProfileById(widget.userId!);
    }
    if (!mounted) return;

    _name.text = loadedProfile?.name ?? '';
    _bio.text = loadedProfile?.bio ?? '';
    _course.text = loadedProfile?.course ?? 'IT Student';
    _location.text = loadedProfile?.location ?? 'Philippines';
    _joinedYear.text = '${loadedProfile?.joinedYear ?? 2025}';
    setState(() {
      _profile = loadedProfile;
      if (viewedUserId != null) {
        _userPostsFuture = postProvider.getPostsByUser(viewedUserId);
        _statsFuture = profileProvider.getStats(viewedUserId);
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
        _statsFuture = profileProvider.getStats(userId);
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
    XFile? image;
    try {
      image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        maxWidth: 1200,
      );
    } catch (error) {
      _showError(error);
      return;
    }
    if (image == null || !mounted) return;

    final profileProvider = context.read<ProfileProvider>();
    final postProvider = context.read<PostProvider>();
    final userId = context.read<AuthStateProvider>().user?.id;

    setState(() => _avatarBusy = true);
    try {
      await profileProvider.updateAvatar(image);
      await _refreshFromProvider(
        profileProvider: profileProvider,
        postProvider: postProvider,
        userId: userId,
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _deleteAvatar() async {
    final profileProvider = context.read<ProfileProvider>();
    final postProvider = context.read<PostProvider>();
    final userId = context.read<AuthStateProvider>().user?.id;

    setState(() => _avatarBusy = true);
    try {
      await profileProvider.deleteAvatar();
      await _refreshFromProvider(
        profileProvider: profileProvider,
        postProvider: postProvider,
        userId: userId,
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'Once you delete your account, your profile, posts, comments, and reactions will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Are you sure you want to continue?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<AuthStateProvider>().deleteAccount();
      if (mounted) context.go('/login');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthStateProvider>().logout();
    if (mounted) context.go('/login');
  }

  void _showError(Object error) {
    if (!mounted) return;
    final raw = error.toString();
    final message = raw.contains('StorageException') ||
                raw.contains('row-level security') ||
                raw.contains('Unauthorized')
            ? 'Image upload is not enabled yet. Run supabase-storage-fix.sql in Supabase SQL Editor, then reload the app.'
            : raw;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAboutEditDialog() {
    final profileProvider = context.read<ProfileProvider>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit About Me'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bio,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'About me'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _course,
                decoration: const InputDecoration(labelText: 'Course / occupation'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _joinedYear,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Joined year'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final joinedYear = int.tryParse(_joinedYear.text.trim());
                if (joinedYear == null || joinedYear < 1900 || joinedYear > 2100) {
                  throw const FormatException('Enter a valid joined year.');
                }
                await profileProvider.updateAbout(
                  name: _name.text,
                  bio: _bio.text,
                  course: _course.text,
                  location: _location.text,
                  joinedYear: joinedYear,
                );
                if (mounted) {
                  setState(() => _profile = profileProvider.profile);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('About Me updated')),
                  );
                }
              } catch (error) {
                _showError(error);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildModernProfile(context);

  Widget _buildModernProfile(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final profile = _profile;
    final isOwnProfile = widget.userId == null || widget.userId == auth.user?.id;
    final email = profile?.email ?? auth.user?.email ?? '';
    final displayName = profile?.name?.trim().isNotEmpty == true
        ? profile!.name!.trim()
        : email.contains('@')
            ? email.split('@').first
            : 'Member';
    final compact = MediaQuery.sizeOf(context).width < 760;

    return AppShell(
      selectedIndex: 2,
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(compact ? 14 : 28, 0, compact ? 14 : 28, 40),
          children: [
            _ModernTopBar(
              displayName: displayName,
              avatarUrl: profile?.avatarUrl,
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: compact
                    ? _ModernProfileContent(
                        displayName: displayName,
                        email: email,
                        profile: profile,
                        postsFuture: _userPostsFuture,
                        canEdit: isOwnProfile,
                        onEdit: _showAboutEditDialog,
                        onDelete: _deleteAccount,
                        onSignOut: isOwnProfile ? _signOut : null,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _ProfileCover(displayName: displayName, email: email),
                                const SizedBox(height: 14),
                                _ProfileIdentity(
                                  displayName: displayName,
                                  profile: profile,
                                  postsFuture: _userPostsFuture,
                                  onEdit: _showAboutEditDialog,
                                  onChangeAvatar: isOwnProfile ? _pickAvatar : null,
                                ),
                                const SizedBox(height: 14),
                                _ProfilePosts(postsFuture: _userPostsFuture),
                                if (isOwnProfile) ...[
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    onPressed: _deleteAccount,
                                    icon: const Icon(Icons.delete_forever_outlined, size: 16),
                                    label: const Text('Delete Account'),
                                    style: OutlinedButton.styleFrom(foregroundColor: _kRed),
                                  ),
                                  TextButton.icon(
                                    onPressed: _signOut,
                                    icon: const Icon(Icons.logout_rounded, size: 16),
                                    label: const Text('Sign out'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 300,
                            child: Column(
                              children: [
                                _ProfileAboutCard(profile: profile, displayName: displayName),
                                const SizedBox(height: 14),
                                _ProfileSkillsCard(),
                                const SizedBox(height: 14),
                                _ProfileStats(statsFuture: _statsFuture),
                                const SizedBox(height: 14),
                                _ProfileGallery(postsFuture: _userPostsFuture),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legacyBuild(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    final profile = _profile;
    final isOwnProfile =
        widget.userId == null || widget.userId == auth.user?.id;
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
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 980;
            final mainColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _ProfileHero(
                    displayName: displayName,
                    email: email,
                  ),
                ),
                const SizedBox(height: 16),
                _ProfileSummaryCard(
                  compact: compact,
                  profile: profile,
                  displayName: displayName,
                  handle: handle,
                  email: email,
                  userPostsFuture: _userPostsFuture,
                  nameController: _name,
                  saving: _saving,
                  avatarBusy: _avatarBusy,
                  canEdit: isOwnProfile,
                  onChangePhoto: _pickAvatar,
                  onDeletePhoto: _deleteAvatar,
                  onSave: _saveName,
                  onDeleteAccount: _deleteAccount,
                  onSignOut: _signOut,
                ),
                const SizedBox(height: 14),
                if (isOwnProfile)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out'),
                    ),
                  ),
                if (isOwnProfile) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kRed,
                        side: const BorderSide(color: _kRed),
                      ),
                      icon: const Icon(Icons.person_remove_outlined, size: 18),
                      label: const Text('Delete account'),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (isOwnProfile && kIsWeb) ...[
                  const _InstallAppCard(),
                  const SizedBox(height: 14),
                ],
                const _ProfileTabs(),
                const SizedBox(height: 14),
                _UserPostsSection(postsFuture: _userPostsFuture),
              ],
            );

            return ListView(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 28,
                18,
                compact ? 16 : 28,
                48,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: compact
                        ? Column(
                            children: [
                              mainColumn,
                              const SizedBox(height: 18),
                              _ProfileSideRail(
                                profile: profile,
                                displayName: displayName,
                                postsFuture: _userPostsFuture,
                                isOwnProfile: isOwnProfile,
                                onEditAbout: isOwnProfile
                                    ? _showAboutEditDialog
                                    : null,
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: mainColumn),
                              const SizedBox(width: 22),
                              SizedBox(
                                width: 330,
                                child: _ProfileSideRail(
                                  profile: profile,
                                  displayName: displayName,
                                  postsFuture: _userPostsFuture,
                                  isOwnProfile: isOwnProfile,
                                  onEditAbout: isOwnProfile
                                      ? _showAboutEditDialog
                                      : null,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModernTopBar extends StatelessWidget {
  const _ModernTopBar({required this.displayName, this.avatarUrl});

  final String displayName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'BLOGVERSE',
              style: TextStyle(
                color: _kInk,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
              child: avatarUrl == null
                  ? Text(displayName.characters.first.toUpperCase())
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCover extends StatelessWidget {
  const _ProfileCover({required this.displayName, required this.email});
  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          Text(email, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.displayName, required this.profile, required this.postsFuture, required this.onEdit, this.onChangeAvatar});
  final String displayName;
  final AppProfile? profile;
  final Future<List<Post>>? postsFuture;
  final VoidCallback onEdit;
  final VoidCallback? onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: _kIndigo,
                  backgroundImage: profile?.avatarUrl == null ? null : NetworkImage(profile!.avatarUrl!),
                  child: profile?.avatarUrl == null ? Text(displayName.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 28)) : null,
                ),
                if (onChangeAvatar != null)
                  Positioned(
                    right: -2,
                    bottom: 0,
                    child: IconButton.filled(
                      onPressed: onChangeAvatar,
                      icon: const Icon(Icons.camera_alt_outlined, size: 15),
                      style: IconButton.styleFrom(backgroundColor: _kInk, foregroundColor: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(displayName, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _kInk))), OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 15), label: const Text('Edit Profile'))]),
                Text('@${displayName.toLowerCase().replaceAll(' ', '')}', style: const TextStyle(color: _kSlate500, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _MiniPill(icon: Icons.location_on_outlined, text: profile?.location ?? 'Philippines'),
                  _MiniPill(icon: Icons.school_outlined, text: profile?.course ?? 'IT Student'),
                  _MiniPill(icon: Icons.calendar_today_outlined, text: 'Joined ${profile?.joinedYear ?? 2025}'),
                ]),
                const SizedBox(height: 12),
                FutureBuilder<List<Post>>(future: postsFuture, builder: (context, snapshot) => Text('${snapshot.data?.length ?? 0}\nPosts', textAlign: TextAlign.center, style: const TextStyle(color: _kInk, fontWeight: FontWeight.w800))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Chip(avatar: Icon(icon, size: 14), label: Text(text));
}

class _ProfileAboutCard extends StatelessWidget {
  const _ProfileAboutCard({required this.profile, required this.displayName});
  final AppProfile? profile;
  final String displayName;
  @override
  Widget build(BuildContext context) => _ModernSection(
    title: 'About Me',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(profile?.bio?.trim().isNotEmpty == true ? profile!.bio! : 'Hi! I am $displayName.', style: const TextStyle(color: _kSlate700, height: 1.45)),
      const SizedBox(height: 12),
      _AboutLine(icon: Icons.code_rounded, label: profile?.course ?? 'IT Student'),
      _AboutLine(icon: Icons.email_outlined, label: profile?.email ?? ''),
      _AboutLine(icon: Icons.location_on_outlined, label: profile?.location ?? 'Philippines'),
    ]),
  );
}

class _ProfileSkillsCard extends StatelessWidget {
  const _ProfileSkillsCard();
  @override
  Widget build(BuildContext context) => const _ModernSection(
    title: 'Skills & Interests',
    child: Wrap(spacing: 6, runSpacing: 6, children: [_SkillPill('Flutter'), _SkillPill('Dart'), _SkillPill('Supabase'), _SkillPill('UI/UX'), _SkillPill('Database'), _SkillPill('Coding')]),
  );
}

class _ProfilePosts extends StatelessWidget {
  const _ProfilePosts({required this.postsFuture});
  final Future<List<Post>>? postsFuture;
  @override
  Widget build(BuildContext context) => _ModernSection(
    title: 'Your Posts',
    child: FutureBuilder<List<Post>>(future: postsFuture, builder: (context, snapshot) {
      final posts = snapshot.data ?? const <Post>[];
      return posts.isEmpty ? const Text('No posts yet.', style: TextStyle(color: _kSlate500)) : Column(children: [for (final post in posts) _ModernPostRow(post: post)]);
    }),
  );
}

class _ProfileGallery extends StatelessWidget {
  const _ProfileGallery({required this.postsFuture});
  final Future<List<Post>>? postsFuture;
  @override
  Widget build(BuildContext context) => _ModernSection(
    title: 'Gallery',
    child: FutureBuilder<List<Post>>(future: postsFuture, builder: (context, snapshot) {
      final urls = <String>[];
      for (final post in snapshot.data ?? const <Post>[]) {
        urls.addAll(post.imageUrls);
      }
      final visibleUrls = urls.take(4).toList();
      return visibleUrls.isEmpty ? const Text('No images yet.', style: TextStyle(color: _kSlate500)) : Wrap(spacing: 6, runSpacing: 6, children: [for (final url in visibleUrls) ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(url, width: 58, height: 58, fit: BoxFit.cover))]);
    }),
  );
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.statsFuture});

  final Future<Map<String, int>>? statsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const <String, int>{};
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                _StatItem(label: 'Posts', value: stats['posts'] ?? 0, icon: Icons.article_outlined),
                _StatItem(label: 'Likes', value: stats['likes'] ?? 0, icon: Icons.favorite_border),
                _StatItem(label: 'Shares', value: stats['shares'] ?? 0, icon: Icons.share_outlined),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.icon});

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 19, color: _kIndigo),
          const SizedBox(height: 4),
          Text('$value', style: const TextStyle(color: _kInk, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: _kSlate500, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ModernProfileBanner extends StatelessWidget {
  const _ModernProfileBanner({
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.onChangeAvatar,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final VoidCallback? onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF132B60), Color(0xFF355AB4), Color(0xFF1A2345)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: avatarUrl == null
                    ? onChangeAvatar
                    : () => _showImagePreview(context, avatarUrl!, 'Profile photo'),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: _kIndigo,
                  backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
                  child: avatarUrl == null
                      ? Text(
                          displayName.characters.first.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 25),
                        )
                      : null,
                ),
              ),
              if (onChangeAvatar != null)
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: Material(
                    color: _kIndigo,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onChangeAvatar,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(Icons.camera_alt_outlined, size: 15, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                Text('@${displayName.toLowerCase().replaceAll(' ', '')}', style: TextStyle(color: Colors.white.withValues(alpha: .8))),
                const SizedBox(height: 4),
                Text('IT Student  •  Developer  •  Lifelong Learner', style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernProfileContent extends StatelessWidget {
  const _ModernProfileContent({
    required this.displayName,
    required this.email,
    required this.profile,
    required this.postsFuture,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    this.onSignOut,
  });

  final String displayName;
  final String email;
  final AppProfile? profile;
  final Future<List<Post>>? postsFuture;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModernSection(
          title: 'About Me',
          actions: canEdit
              ? Row(
                  children: [
                    TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 14), label: const Text('Edit')),
                    TextButton.icon(onPressed: onDelete, style: TextButton.styleFrom(foregroundColor: _kRed), icon: const Icon(Icons.delete_outline, size: 14), label: const Text('Delete')),
                  ],
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.bio?.trim().isNotEmpty == true
                    ? profile!.bio!.trim()
                    : 'Hi! I am $displayName, an IT student who loves coding, building systems, and exploring new technologies.',
                style: const TextStyle(color: _kSlate700, fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _AboutLine(
                    icon: Icons.code_rounded,
                    label: profile?.course?.trim().isNotEmpty == true
                        ? profile!.course!.trim()
                        : 'IT Student',
                  ),
                  _AboutLine(
                    icon: Icons.location_on_outlined,
                    label: profile?.location?.trim().isNotEmpty == true
                        ? profile!.location!.trim()
                        : 'Philippines',
                  ),
                  _AboutLine(
                    icon: Icons.calendar_today_outlined,
                    label: 'Joined ${profile?.joinedYear ?? 2025}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _ModernSection(
          title: 'Skills',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _SkillPill('Web Development'), _SkillPill('Mobile Development'), _SkillPill('Database Management'), _SkillPill('UI/UX Design'), _SkillPill('Problem Solving'), _SkillPill('Teamwork'),
          ]),
        ),
        const SizedBox(height: 12),
        _ModernSection(
          title: 'Recent Posts',
          action: TextButton(onPressed: () {}, child: const Text('View All →')),
          child: FutureBuilder<List<Post>>(
            future: postsFuture,
            builder: (context, snapshot) {
              final posts = snapshot.data ?? const <Post>[];
              if (posts.isEmpty) return const Text('No posts yet.', style: TextStyle(color: _kSlate500));
              return Column(children: [for (final post in posts.take(4)) _ModernPostRow(post: post)]);
            },
          ),
        ),
        if (canEdit) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(foregroundColor: _kRed, side: BorderSide(color: _kRed.withValues(alpha: .35))),
              icon: const Icon(Icons.delete_forever_outlined, size: 16),
              label: const Text('Delete Account'),
            ),
          ),
          if (onSignOut != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Sign out'),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ModernSection extends StatelessWidget {
  const _ModernSection({required this.title, required this.child, this.action, this.actions});

  final String title;
  final Widget child;
  final Widget? action;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(title, style: const TextStyle(color: _kInk, fontSize: 14, fontWeight: FontWeight.w900))), if (actions != null) actions!, if (action != null) action!]),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }
}

class _ModernPostRow extends StatelessWidget {
  const _ModernPostRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/posts/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 48, height: 36, child: post.imageUrls.isEmpty ? const ColoredBox(color: _kSlate100) : Image.network(post.imageUrls.first, fit: BoxFit.cover))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _kInk, fontSize: 11, fontWeight: FontWeight.w900)), Text(post.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _kSlate500, fontSize: 10)), Text(DateFormat.MMMd().format(post.createdAt), style: const TextStyle(color: _kSlate400, fontSize: 9))])),
          const Icon(Icons.chevron_right, color: _kSlate400, size: 18),
        ]),
      ),
    );
  }
}

class _InstallAppCard extends StatelessWidget {
  const _InstallAppCard();

  void _showInstallSteps(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Install BlogVerse safely'),
        content: const Text(
          'In Chrome on your phone, tap ⋮ then choose “Install app” or “Add to Home screen”. Only install this app from your trusted HTTPS website.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      child: ListTile(
        leading: const Icon(Icons.verified_user_outlined, color: _kIndigo),
        title: const Text('Install BlogVerse on your phone'),
        subtitle: const Text('Safe install through Chrome HTTPS'),
        trailing: TextButton(
          onPressed: () => _showInstallSteps(context),
          child: const Text('Install app'),
        ),
      ),
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kSlate200),
      ),
      child: const Row(
        children: [
          _ProfileTab(label: 'Posts', active: true),
          _ProfileTab(label: 'Comments'),
          _ProfileTab(label: 'About'),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? _kIndigo : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _kIndigo : _kSlate500,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProfileSideRail extends StatelessWidget {
  const _ProfileSideRail({
    required this.profile,
    required this.displayName,
    required this.postsFuture,
    required this.isOwnProfile,
    this.onEditAbout,
  });

  final AppProfile? profile;
  final String displayName;
  final Future<List<Post>>? postsFuture;
  final bool isOwnProfile;
  final VoidCallback? onEditAbout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SideCard(
          title: 'About Me',
          icon: Icons.person_outline_rounded,
          action: isOwnProfile
              ? TextButton.icon(
                  onPressed: onEditAbout,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit'),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi! I am $displayName.',
                style: const TextStyle(
                  color: _kInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'I am passionate about coding, web development, and building useful projects with Flutter and Supabase.',
                style: TextStyle(color: _kSlate700, height: 1.45),
              ),
              const SizedBox(height: 14),
              const _AboutLine(
                icon: Icons.code_rounded,
                label: 'Developer',
              ),
              _AboutLine(
                icon: Icons.mail_outline_rounded,
                label: profile?.email ?? 'No email',
              ),
              const _AboutLine(
                icon: Icons.location_on_outlined,
                label: 'Philippines',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _SideCard(
          title: 'Skills & Interests',
          icon: Icons.local_offer_outlined,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SkillPill('Flutter'),
              _SkillPill('Dart'),
              _SkillPill('Supabase'),
              _SkillPill('UI/UX'),
              _SkillPill('Database'),
              _SkillPill('Coding'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SideCard(
          title: 'Stats',
          icon: Icons.bar_chart_rounded,
          child: FutureBuilder<List<Post>>(
            future: postsFuture,
            builder: (context, snapshot) {
              final posts = snapshot.data?.length ?? 0;
              return Row(
                children: [
                  Expanded(child: _MiniStat(value: '$posts', label: 'Posts')),
                  const Expanded(child: _MiniStat(value: '0', label: 'Likes')),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _SideCard(
          title: 'Gallery',
          icon: Icons.image_outlined,
          child: FutureBuilder<List<Post>>(
            future: postsFuture,
            builder: (context, snapshot) {
              final images = (snapshot.data ?? const <Post>[])
                  .expand((post) => post.imageUrls)
                  .take(4)
                  .toList();
              if (images.isEmpty) {
                return const Text(
                  'Post images will appear here.',
                  style: TextStyle(color: _kSlate500, fontSize: 12),
                );
              }
              return Row(
                children: [
                  for (final image in images)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(image, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kSlate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _kIndigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _kInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AboutLine extends StatelessWidget {
  const _AboutLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kSlate500),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kSlate700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillPill extends StatelessWidget {
  const _SkillPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _kIndigo,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(color: Color(0xFFF4F2FF)),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _kIndigo,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _kSlate500,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.displayName, required this.email});

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      alignment: Alignment.bottomLeft,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), _kIndigo, Color(0xFF7C3AED)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    required this.avatarBusy,
    required this.canEdit,
    required this.onChangePhoto,
    required this.onDeletePhoto,
    required this.onSave,
    required this.onDeleteAccount,
    required this.onSignOut,
  });

  final bool compact;
  final AppProfile? profile;
  final String displayName;
  final String handle;
  final String email;
  final Future<List<Post>>? userPostsFuture;
  final TextEditingController nameController;
  final bool saving;
  final bool avatarBusy;
  final bool canEdit;
  final VoidCallback onChangePhoto;
  final VoidCallback onDeletePhoto;
  final VoidCallback onSave;
  final VoidCallback onDeleteAccount;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          onChangePhoto: canEdit && !avatarBusy ? onChangePhoto : null,
        ),
        const SizedBox(width: 24),
        Expanded(child: _profileDetails()),
        if (canEdit) ...[
          const SizedBox(width: 24),
          _editButton(context),
        ],
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
              onChangePhoto: canEdit && !avatarBusy ? onChangePhoto : null,
              size: 86,
            ),
            const SizedBox(width: 16),
            Expanded(child: _identityText()),
          ],
        ),
        const SizedBox(height: 18),
        _stats(),
        if (canEdit) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: _editButton(context),
          ),
        ],
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
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoPill(
              icon: Icons.location_on_outlined,
              label: 'Philippines',
            ),
            _InfoPill(
              icon: Icons.school_outlined,
              label: 'IT Student',
            ),
            _InfoPill(
              icon: Icons.calendar_today_outlined,
              label: 'Joined Aug 2025',
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
              child: _StatBox(value: postCount, label: 'Posts'),
            ),
            const SizedBox(width: 1),
          ],
        );
      },
    );
  }

  Widget _editButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showEditDialog(context),
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: const Text('Edit Profile'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kInk,
        side: const BorderSide(color: _kSlate200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: avatarBusy ? null : onChangePhoto,
                      icon: avatarBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera_outlined, size: 16),
                      label: const Text('Photo'),
                    ),
                  ),
                  if (profile?.avatarUrl != null) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Remove photo',
                      onPressed: avatarBusy ? null : onDeletePhoto,
                      color: _kRed,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onDeleteAccount,
                  style: TextButton.styleFrom(foregroundColor: _kRed),
                  icon: const Icon(Icons.person_remove_outlined, size: 17),
                  label: const Text('Delete account permanently'),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded, size: 17),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: saving
                ? null
                : () {
                    Navigator.of(context).pop();
                    onSave();
                  },
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(saving ? 'Saving' : 'Save'),
          ),
        ],
      ),
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
  final VoidCallback? onChangePhoto;
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
            child: GestureDetector(
              onTap: hasPhoto
                  ? () =>
                      _showImagePreview(context, avatarUrl!, 'Profile photo')
                  : null,
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
          ),
          if (onChangePhoto != null)
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

void _showImagePreview(BuildContext context, String url, String title) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 280,
                child: Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              tooltip: 'Close $title preview',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    ),
  );
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
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _kInk,
              fontSize: 17,
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
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kSlate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go('/posts/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(12),
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
