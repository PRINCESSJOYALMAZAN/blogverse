import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_profile.dart';
import '../providers/auth_provider.dart';
import 'app_logo.dart';

const _kSideBg = Color(0xFF0F172A);
const _kSideBorder = Color(0xFF1E293B);
const _kSideText = Color(0xFF94A3B8);
const _kSideActive = Color(0xFFEEF2FF);
const _kIndigo = Color(0xFF4F46E5);
const _kIndigoLight = Color(0xFFA5B4FC);

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
      width: 220,
      color: _kSideBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: AppLogo(iconSize: 32, fontSize: 16),
            ),
            Container(height: 1, color: _kSideBorder),
            const SizedBox(height: 8),
            _SideItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Feed',
              selected: selectedIndex == 0,
              onTap: () => onDestinationSelected(0),
            ),
            _SideItem(
              icon: Icons.edit_outlined,
              activeIcon: Icons.edit_rounded,
              label: 'Write',
              selected: selectedIndex == 1,
              onTap: () => auth.isLoggedIn
                  ? onDestinationSelected(1)
                  : context.go('/login'),
            ),
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
            Container(height: 1, color: _kSideBorder),
            if (auth.isLoggedIn)
              _UserCard(
                displayName: displayName,
                email: email,
                avatarUrl: profile?.avatarUrl,
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Sign in'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kIndigo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
                label: 'Feed',
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _kIndigo,
                  backgroundImage: avatarUrl == null || avatarUrl!.isEmpty
                      ? null
                      : NetworkImage(avatarUrl!),
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? Text(
                          displayName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kSideText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await context.read<AuthStateProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, size: 14),
            label: const Text('Sign out'),
            style: TextButton.styleFrom(
              foregroundColor: _kSideText,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? _kIndigo.withValues(alpha: .15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          hoverColor: Colors.white.withValues(alpha: .05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 18,
                  color: selected ? _kIndigoLight : _kSideText,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? _kSideActive : _kSideText,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (selected) ...[
                  const Spacer(),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: _kIndigoLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
