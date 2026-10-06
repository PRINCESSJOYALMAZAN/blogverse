import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_profile.dart';
import '../providers/auth_provider.dart';
import 'app_logo.dart';

const _kSideBg = Color(0xFF0F172A);
const _kSideText = Color(0xFF94A3B8);
const _kIndigo = Color(0xFF4F46E5);
const _kViolet = Color(0xFF6D5DFB);

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.auth,
    required this.profile,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final AuthStateProvider auth;
  final AppProfile? profile;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name?.toString().trim() ??
        auth.user?.userMetadata?['name']?.toString().trim();
    final email = auth.user?.email ?? '';
    final displayName = name?.isNotEmpty == true
        ? name!
        : email.split('@').firstOrNull ?? 'Member';

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: _kSideBg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101B33), Color(0xFF07111F)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: -84,
            bottom: -70,
            child: _SideGlow(size: 250, color: Color(0xFF284B9A)),
          ),
          const Positioned(
            right: -130,
            bottom: 120,
            child: _SideGlow(size: 220, color: Color(0xFF4F46E5)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 18),
                    child: Row(
                      children: [
                        AppLogo(iconSize: 42),
                        SizedBox(width: 10),
                        Text(
                          'BLOGVERSE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SideItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    selected: selectedIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                  const SizedBox(height: 6),
                  _SideItem(
                    icon: Icons.edit_outlined,
                    activeIcon: Icons.edit_rounded,
                    label: 'Write',
                    selected: selectedIndex == 1,
                    onTap: () => auth.isLoggedIn
                        ? onDestinationSelected(1)
                        : context.go('/login'),
                  ),
                  const SizedBox(height: 6),
                  _SideItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    selected: selectedIndex == 2,
                    onTap: () => auth.isLoggedIn
                        ? onDestinationSelected(2)
                        : context.go('/login'),
                  ),
                  const Spacer(),
                  if (auth.isLoggedIn)
                    _UserCard(
                      displayName: displayName,
                      email: email,
                      avatarUrl: profile?.avatarUrl,
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.login_rounded, size: 16),
                      label: const Text('Sign in'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kViolet,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.auth,
    required this.selectedIndex,
    required this.onTap,
  });

  final AuthStateProvider auth;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _BottomItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _BottomItem(
                icon: Icons.edit_outlined,
                activeIcon: Icons.edit_rounded,
                label: 'Write',
                selected: selectedIndex == 1,
                onTap: () => auth.isLoggedIn ? onTap(1) : context.go('/login'),
              ),
              _BottomItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                selected: selectedIndex == 2,
                onTap: () => auth.isLoggedIn ? onTap(2) : context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _kViolet,
                backgroundImage: avatarUrl == null || avatarUrl!.isEmpty
                    ? null
                    : NetworkImage(avatarUrl!),
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Text(
                        displayName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kSideText,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () async {
            await context.read<AuthStateProvider>().logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout_rounded, size: 15),
          label: const Text('Sign out'),
          style: TextButton.styleFrom(
            foregroundColor: _kSideText,
            alignment: Alignment.centerLeft,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF6D5DFB), Color(0xFF4F46E5)],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          hoverColor: Colors.white.withValues(alpha: .06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 20,
                  color: selected ? Colors.white : _kSideText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : _kSideText,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideGlow extends StatelessWidget {
  const _SideGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .18),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 22,
              color: selected ? _kIndigo : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? _kIndigo : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
